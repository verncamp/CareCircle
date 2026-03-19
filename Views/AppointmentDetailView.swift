//
//  AppointmentDetailView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct AppointmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appointment: Appointment

    @State private var ai = AIAssistant()
    @State private var aiSummary: String?
    @State private var suggestedTasks: [SuggestedTask] = []
    @State private var showingEdit = false
    @State private var newChecklistItem = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerCard

                // Checklist
                checklistCard

                // Notes
                notesCard

                // AI Actions
                if ai.isAvailable && !appointment.notes.isEmpty {
                    aiCard
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .adaptiveWidth()
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditAppointmentView(appointment: appointment)
        }
        .onAppear {
            aiSummary = appointment.aiSummary
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(appointment.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
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
                .frame(width: 56, height: 56)
                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.date.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.teal)
                        .fontWeight(.medium)

                    if !appointment.location.isEmpty {
                        Label(appointment.location, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Status
            let isPast = appointment.date < Date()
            HStack(spacing: 6) {
                Image(systemName: isPast ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(isPast ? .green : .teal)
                Text(isPast ? "Completed" : "Upcoming")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isPast ? .green : .teal)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((isPast ? Color.green : Color.teal).opacity(0.1), in: Capsule())
        }
        .glassCard()
    }

    // MARK: - Checklist

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            let completed = appointment.checklistItems.filter(\.isCompleted).count
            let total = appointment.checklistItems.count

            HStack {
                SectionHeader(title: "Checklist")
                if total > 0 {
                    Spacer()
                    Text("\(completed)/\(total)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(completed == total ? .green : .secondary)
                }
            }

            if total > 0 {
                ProgressView(value: Double(completed), total: Double(max(total, 1)))
                    .tint(completed == total ? .green : .teal)
            }

            ForEach(Array(appointment.checklistItems.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            appointment.checklistItems[index].isCompleted.toggle()
                            try? modelContext.save()
                        }
                    } label: {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                    }

                    Text(item.title)
                        .font(.subheadline)
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)

                    Spacer()

                    // Delete
                    Button {
                        withAnimation {
                            appointment.checklistItems.remove(at: index)
                            try? modelContext.save()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                    }
                }
            }

            // Add item
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(.teal)

                TextField("Add item", text: $newChecklistItem)
                    .font(.subheadline)
                    .onSubmit { addChecklistItem() }

                if !newChecklistItem.isEmpty {
                    Button("Add") { addChecklistItem() }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.teal)
                }
            }
        }
        .glassCard()
    }

    private func addChecklistItem() {
        guard !newChecklistItem.isEmpty else { return }
        appointment.checklistItems.append(ChecklistItem(title: newChecklistItem))
        newChecklistItem = ""
        try? modelContext.save()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes")

            if appointment.notes.isEmpty {
                Text("No notes yet. Tap Edit to add notes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(appointment.notes)
                    .font(.subheadline)
                    .lineSpacing(4)
            }
        }
        .glassCard()
    }

    // MARK: - AI Actions

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.teal)
                SectionHeader(title: "AI Assistant")
                if ai.isProcessing {
                    ProgressView().controlSize(.small)
                }
            }

            // Summary
            if let summary = aiSummary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Summary")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.teal)
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }

            // Suggested tasks
            if !suggestedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Tasks")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.teal)

                    ForEach(suggestedTasks, id: \.title) { task in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle")
                                .foregroundStyle(.teal)
                                .font(.caption)
                            Text(task.title)
                                .font(.subheadline)
                            Spacer()
                            Text(task.priority)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.1), in: Capsule())
                        }
                    }

                    Button {
                        saveExtractedTasks()
                    } label: {
                        Label("Save as Tasks", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.teal)
                    .padding(.top, 4)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    asyncRun { @MainActor in
                        let result = await ai.summarizeNotes(appointment.notes)
                        if let result {
                            aiSummary = result
                            appointment.aiSummary = result
                            try? modelContext.save()
                        }
                    }
                } label: {
                    Label("Summarize", systemImage: "sparkles")
                }

                Button {
                    asyncRun { @MainActor in
                        suggestedTasks = await ai.extractTasks(from: appointment.notes)
                    }
                } label: {
                    Label("Extract Tasks", systemImage: "list.bullet")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.teal)
            .disabled(ai.isProcessing)
        }
        .glassCard()
    }

    private func saveExtractedTasks() {
        for suggested in suggestedTasks {
            let priority: TaskPriority = switch suggested.priority.lowercased() {
            case "urgent": .urgent
            case "high": .high
            case "low": .low
            default: .normal
            }

            let task = Task(title: suggested.title, priority: priority)
            task.parentProfile = appointment.parentProfile
            modelContext.insert(task)
        }
        try? modelContext.save()
        suggestedTasks = []
    }
}

// MARK: - Edit Appointment

struct EditAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var appointment: Appointment

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $appointment.title)
                    DatePicker("Date & Time", selection: $appointment.date)
                    TextField("Location", text: $appointment.location)
                }

                Section("Notes") {
                    TextEditor(text: $appointment.notes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Edit Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        appointment.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppointmentDetailView(appointment: Appointment(
            title: "Cardiology Follow-up",
            date: Date(),
            location: "St. Mary's Hospital",
            notes: "Blood pressure has improved. Continue current medication. Schedule echo in 2 weeks. Monitor dizziness.",
            checklistItems: [
                ChecklistItem(title: "Insurance card", isCompleted: true),
                ChecklistItem(title: "Medication list", isCompleted: true),
                ChecklistItem(title: "Lab report", isCompleted: false)
            ]
        ))
    }
    .modelContainer(for: [
        ParentProfile.self, Appointment.self, Task.self,
        Document.self, FamilyMember.self, Expense.self,
        ExpenseAccount.self, UpdateFeedItem.self
    ], inMemory: true)
}
