//
//  AIAssistant.swift
//  CareCircle
//
//  On-device AI using Apple Foundation Models.
//  Runs locally — no data leaves the device.
//

import Foundation
import FoundationModels

@Observable
@MainActor
class AIAssistant {
    var isProcessing = false
    var lastError: String?

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
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
