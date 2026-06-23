//
//  AIAssistant.swift
//  CareCircle
//
//  Uses Apple Foundation Models when available at runtime.
//  On unsupported devices, appointment-note summaries can optionally
//  fall back to a backend-managed cloud summary endpoint.
//

import Foundation
import FoundationModels

enum AIAvailabilityState: Equatable {
    case available
    case appleIntelligenceNotEnabled
    case modelNotReady
    case deviceNotEligible
    case unavailable

    init(systemAvailability: SystemLanguageModel.Availability) {
        switch systemAvailability {
        case .available:
            self = .available
        case .unavailable(.deviceNotEligible):
            self = .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            self = .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            self = .modelNotReady
        case .unavailable(_):
            self = .unavailable
        }
    }

    var isReadyForOnDeviceFeatures: Bool {
        self == .available
    }

    var title: String {
        switch self {
        case .available:
            return "AI Ready"
        case .appleIntelligenceNotEnabled:
            return "Turn On Apple Intelligence"
        case .modelNotReady:
            return "AI Not Ready Yet"
        case .deviceNotEligible:
            return "Cloud Summaries Available"
        case .unavailable:
            return "AI Unavailable"
        }
    }

    var message: String {
        switch self {
        case .available:
            return "On-device AI features are ready on this iPhone."
        case .appleIntelligenceNotEnabled:
            return "This iPhone supports Apple Intelligence, but it is turned off. Enable it in Settings for better summaries and task help."
        case .modelNotReady:
            return "Apple Intelligence is still downloading or not ready yet. Core workflows still work without AI."
        case .deviceNotEligible:
            return "This iPhone does not support Apple Intelligence. You can optionally enable cloud summaries for simple appointment-note summaries."
        case .unavailable:
            return "AI features are unavailable right now. Core workflows still work without AI."
        }
    }
}

@Observable
@MainActor
class AIAssistant {
    private let model = SystemLanguageModel.default

    var isProcessing = false
    var lastError: String?

    var availabilityState: AIAvailabilityState {
        AIAvailabilityState(systemAvailability: model.availability)
    }

    var isAvailable: Bool {
        availabilityState.isReadyForOnDeviceFeatures
    }

    var isCloudSummaryConfigured: Bool {
        Self.cloudSummaryEndpoint != nil
    }

    var canUseCloudSummaryFallback: Bool {
        availabilityState == .deviceNotEligible
            && isCloudSummaryConfigured
            && UserDefaults.standard.bool(forKey: Self.cloudSummariesEnabledKey)
    }

    // MARK: - Daily Briefing

    func generateBriefing(
        profile: ParentProfile,
        appointments: [Appointment],
        tasks: [Task],
        updates: [UpdateFeedItem]
    ) async -> String? {
        guard isAvailable else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        let session = LanguageModelSession(
            instructions: """
            You are a warm, supportive caregiving assistant for a family \
            coordinating care for an aging parent. Give brief, actionable \
            daily briefings in 2-3 sentences. Be caring but practical. \
            Never give medical advice or diagnoses.
            """
        )

        // Build context
        var context = "Parent: \(profile.name)"
        context += "\nStatus: \(profile.statusMessage)"

        let upcoming = appointments
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
            .prefix(3)

        if !upcoming.isEmpty {
            context += "\n\nUpcoming appointments:"
            for appt in upcoming {
                context += "\n- \(appt.title) on \(appt.date.formatted(date: .abbreviated, time: .shortened))"
                if !appt.location.isEmpty {
                    context += " at \(appt.location)"
                }
            }
        }

        let openTasks = tasks.filter { !$0.isCompleted }
        let urgentTasks = openTasks.filter { $0.priority == .urgent || $0.priority == .high }

        context += "\n\nOpen tasks: \(openTasks.count) total"
        if !urgentTasks.isEmpty {
            context += "\nUrgent/high priority:"
            for task in urgentTasks.prefix(5) {
                context += "\n- \(task.title)"
                if let due = task.dueDate {
                    context += " (due \(due.formatted(date: .abbreviated, time: .omitted)))"
                }
            }
        }

        if !updates.isEmpty {
            let recent = updates.sorted { $0.timestamp > $1.timestamp }.prefix(3)
            context += "\n\nRecent activity:"
            for update in recent {
                context += "\n- \(update.authorName): \(update.message)"
            }
        }

        do {
            let response = try await session.respond(
                to: "Give a brief daily care briefing based on this status:\n\(context)"
            )
            return response.content
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Note Summarization

    func summarizeNotes(_ notes: String) async -> String? {
        guard !notes.isEmpty else { return nil }

        switch availabilityState {
        case .available:
            return await summarizeNotesOnDevice(notes)
        case .deviceNotEligible where canUseCloudSummaryFallback:
            return await summarizeNotesInCloud(notes)
        default:
            return nil
        }
    }

    private func summarizeNotesOnDevice(_ notes: String) async -> String? {
        guard isAvailable, !notes.isEmpty else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        let session = LanguageModelSession(
            instructions: """
            Summarize medical appointment notes into clear, concise bullet points. \
            Focus on: key findings, medication changes, follow-up actions needed, \
            and any concerns raised. Stay factual — never interpret results or \
            add medical advice. Use plain language a family member can understand.
            """
        )

        do {
            let response = try await session.respond(to: notes)
            return response.content
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func summarizeNotesInCloud(_ notes: String) async -> String? {
        guard !notes.isEmpty else { return nil }
        guard let endpoint = Self.cloudSummaryEndpoint else {
            lastError = "Cloud summaries are not configured for this build."
            return nil
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 20
            request.httpBody = try JSONEncoder().encode(
                CloudSummaryRequest(
                    notes: notes,
                    noteType: "appointment_note_summary",
                    client: "ios"
                )
            )

            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.timeoutIntervalForRequest = 15
            sessionConfig.timeoutIntervalForResource = 20
            let session = URLSession(configuration: sessionConfig)
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Cloud summary service returned an invalid response."
                return nil
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                lastError = "Cloud summary service returned \(httpResponse.statusCode)."
                return nil
            }

            let summary = try JSONDecoder().decode(CloudSummaryResponse.self, from: data)
            let cleaned = summary.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty {
                lastError = "Cloud summary service returned an empty summary."
                return nil
            }
            return cleaned
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                lastError = "Cloud summary request timed out. Please try again."
            } else {
                lastError = error.localizedDescription
            }
            return nil
        }
    }

    // MARK: - Task Extraction

    func extractTasks(from notes: String) async -> [SuggestedTask] {
        guard isAvailable, !notes.isEmpty else { return [] }

        isProcessing = true
        defer { isProcessing = false }

        let session = LanguageModelSession(
            instructions: """
            Extract actionable follow-up tasks from medical appointment notes. \
            Each task should be specific and practical. Assign a priority: \
            urgent (needs immediate action), high (within a few days), \
            normal (within a week), or low (when convenient).
            """
        )

        do {
            let response = try await session.respond(
                to: "Extract follow-up tasks from these notes:\n\(notes)",
                generating: SuggestedTaskList.self
            )
            return response.content.tasks
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    // MARK: - Document Category Suggestion

    func suggestCategory(for title: String) async -> String? {
        guard isAvailable else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        let session = LanguageModelSession(
            instructions: """
            Given a document title, suggest the best category from this list: \
            Insurance, Medical Records, Legal Documents, Medications, \
            Lab Results, Vaccinations, Other. \
            Respond with only the category name.
            """
        )

        do {
            let response = try await session.respond(to: title)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
    // MARK: - Document Label from Content

    /// Analyze OCR-extracted text to generate a descriptive title and category for a scanned document.
    func labelDocument(from extractedText: String) async -> DocumentLabel? {
        guard isAvailable, !extractedText.isEmpty else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        let session = LanguageModelSession(
            instructions: """
            You are a document filing assistant for a family caregiver app. \
            Given OCR-extracted text from a scanned document, produce: \
            1. A short, descriptive title (max 8 words) that a family member \
               would recognize at a glance. \
            2. The best category from this exact list: Insurance, Medical Records, \
               Legal Documents, Medications, Lab Results, Vaccinations, Other. \
            Base your answer only on the text provided. If the text is too \
            garbled to classify, use category "Other" and title "Scanned Document".
            """
        )

        do {
            let response = try await session.respond(
                to: "Label this document:\n\(extractedText.prefix(2000))",
                generating: DocumentLabel.self
            )
            return response.content
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
}

private extension AIAssistant {
    static let cloudSummariesEnabledKey = "cloudSummariesEnabled"
    static let cloudSummaryEndpointDefaultsKey = "cloudSummaryEndpoint"
    static let cloudSummaryEndpointInfoKey = "CARECIRCLE_SUMMARY_API_URL"

    static var cloudSummaryEndpoint: URL? {
        if let rawValue = UserDefaults.standard.string(forKey: cloudSummaryEndpointDefaultsKey),
           !rawValue.isEmpty,
           let url = URL(string: rawValue) {
            return url
        }

        if let rawValue = Bundle.main.object(forInfoDictionaryKey: cloudSummaryEndpointInfoKey) as? String,
           !rawValue.isEmpty,
           let url = URL(string: rawValue) {
            return url
        }

        return nil
    }
}

private struct CloudSummaryRequest: Encodable {
    let notes: String
    let noteType: String
    let client: String
}

private struct CloudSummaryResponse: Decodable {
    let summary: String
}

// MARK: - Structured Output Types

@Generable
struct DocumentLabel {
    @Guide(description: "Short descriptive title for the document, max 8 words")
    var title: String

    @Guide(description: "Category: Insurance, Medical Records, Legal Documents, Medications, Lab Results, Vaccinations, or Other")
    var category: String
}

@Generable
struct SuggestedTask {
    @Guide(description: "Short, actionable task title")
    var title: String

    @Guide(description: "Priority: urgent, high, normal, or low")
    var priority: String
}

@Generable
struct SuggestedTaskList {
    @Guide(description: "List of follow-up tasks extracted from notes")
    var tasks: [SuggestedTask]
}
