//
//  TodayView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    @State private var ai = AIAssistant()
    @State private var briefing: String?
    @State private var showBriefing = false

    var activeProfile: ParentProfile? { parentProfiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = activeProfile {
                    VStack(spacing: 20) {
                        parentHeroCard(profile)

                        // AI Briefing
                        if ai.isAvailable {
                            aiBriefingCard(profile)
                        }

                        if let appt = nextAppointment(from: profile) {
                            appointmentCard(appt)
                        }

                        criticalTasksSection(from: profile)
                        recentUpdatesSection(from: profile)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .adaptiveWidth()
                } else {
                    emptyState
                }
            }
            .navigationTitle("Today")
            .screenBackground()
        }
    }

    // MARK: - AI Briefing Card

    private func aiBriefingCard(_ profile: ParentProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.teal)
                Text("Daily Briefing")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                if ai.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let briefing = briefing {
                Text(briefing)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)

                Button("Refresh") {
                    asyncRun { await generateBriefing(profile) }
                }
                .font(.caption)
                .foregroundStyle(.teal)
            } else {
                Button {
                    asyncRun { await generateBriefing(profile) }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate today's briefing")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.teal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .disabled(ai.isProcessing)
            }
        }
        .glassCard()
    }

    private func generateBriefing(_ profile: ParentProfile) async {
        briefing = await ai.generateBriefing(
            profile: profile,
            appointments: profile.appointments,
            tasks: profile.tasks,
            updates: profile.updateFeedItems
        )
    }

    // MARK: - Parent Hero Card

    private func parentHeroCard(_ profile: ParentProfile) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                AvatarView(name: profile.name, size: 56, gradient: [.teal, .mint])

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let dob = profile.dateOfBirth {
                        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
                        Text("Age \(age)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                }
                .shadow(color: .red.opacity(0.3), radius: 8, y: 2)
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text(profile.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .glassCard()
    }

    // MARK: - Next Appointment Card

    private func appointmentCard(_ appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Next Up")

            HStack(alignment: .top, spacing: 14) {
                // Date badge
                VStack(spacing: 2) {
                    Text(appointment.date.formatted(.dateTime.day()))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(appointment.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                .frame(width: 52, height: 52)
                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.title)
                        .font(.headline)

                    if !appointment.location.isEmpty {
                        Label(appointment.location, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(appointment.date.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.teal)
                        .fontWeight(.medium)
                }

                Spacer()
            }

            if !appointment.checklistItems.isEmpty {
                let completed = appointment.checklistItems.filter(\.isCompleted).count
                let total = appointment.checklistItems.count

                HStack(spacing: 8) {
                    ProgressView(value: Double(completed), total: Double(total))
                        .tint(.teal)

                    Text("\(completed)/\(total) ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Critical Tasks

    private func criticalTasksSection(from profile: ParentProfile) -> some View {
        let tasks = criticalTasks(from: profile)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Critical Tasks", action: "See all")

            if tasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("All clear")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(tasks) { task in
                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    task.isCompleted.toggle()
                                    task.updatedAt = Date()
                                    try? modelContext.save()
                                }
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(task.isCompleted ? .green : task.priority.color.opacity(0.6))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .strikethrough(task.isCompleted)
                                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                                if let due = task.dueDate {
                                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: task.priority.icon)
                                .foregroundStyle(task.priority.color)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Recent Updates

    private func recentUpdatesSection(from profile: ParentProfile) -> some View {
        let updates = recentUpdates(from: profile)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent Updates")

            if updates.isEmpty {
                Text("No recent updates")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(updates.enumerated()), id: \.element.id) { index, update in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(colorForUpdateType(update.type))
                                    .frame(width: 8, height: 8)

                                if index < updates.count - 1 {
                                    Rectangle()
                                        .fill(.quaternary)
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 8)
                            .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(update.authorName): \"\(update.message)\"")
                                    .font(.subheadline)

                                Text(update.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.bottom, index < updates.count - 1 ? 16 : 0)

                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.circle")
                .font(.system(size: 72))
                .foregroundStyle(.teal.opacity(0.6))

            Text("Welcome to CareCircle")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create a parent profile to start coordinating care")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { createSampleProfile() }) {
                Label("Get Started", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Helpers

    func nextAppointment(from profile: ParentProfile) -> Appointment? {
        profile.appointments
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
            .first
    }

    func criticalTasks(from profile: ParentProfile) -> [Task] {
        profile.tasks
            .filter { !$0.isCompleted && ($0.priority == .high || $0.priority == .urgent) }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
            .prefix(5)
            .map { $0 }
    }

    func recentUpdates(from profile: ParentProfile) -> [UpdateFeedItem] {
        profile.updateFeedItems
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(5)
            .map { $0 }
    }

    func colorForUpdateType(_ type: UpdateType) -> Color {
        switch type {
        case .note:             return .blue
        case .taskCompleted:    return .green
        case .documentAdded:    return .purple
        case .appointmentAdded: return .orange
        case .expenseAdded:     return .pink
        }
    }

    func createSampleProfile() {
        SampleDataGenerator.generateSampleData(modelContext: modelContext)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, UpdateFeedItem.self,
            FamilyMember.self, ExpenseAccount.self,
            Document.self, Expense.self
        ], inMemory: true)
}
