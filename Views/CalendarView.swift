//
//  CalendarView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Query private var parentProfiles: [ParentProfile]
    @State private var showingAddAppointment = false
    @State private var ai = AIAssistant()
    @State private var summaries: [UUID: String] = [:]
    @State private var extractedTasks: [UUID: [SuggestedTask]] = [:]

    var upcomingAppointments: [Appointment] {
        appointments.filter { $0.date > Date() }
    }

    var groupedByDate: [(key: String, appointments: [Appointment])] {
        let grouped = Dictionary(grouping: upcomingAppointments) { appt in
            appt.date.formatted(date: .complete, time: .omitted)
        }
        return grouped
            .map { (key: $0.key, appointments: $0.value) }
            .sorted { ($0.appointments.first?.date ?? .distantPast) < ($1.appointments.first?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if upcomingAppointments.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedByDate, id: \.key) { group in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(group.key)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                ForEach(group.appointments) { appointment in
                                    appointmentCard(appointment)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .adaptiveWidth()
            }
            .navigationTitle("Calendar")
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddAppointment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView()
            }
        }
    }

    // MARK: - Appointment Card

    private func appointmentCard(_ appointment: Appointment) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Time column
            Text(appointment.date.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.teal)
                .frame(width: 64, alignment: .trailing)

            // Accent bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(.teal.opacity(0.3))
                .frame(width: 3)
                .padding(.vertical, 4)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.title)
                    .font(.headline)

                if !appointment.location.isEmpty {
                    Label(appointment.location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !appointment.checklistItems.isEmpty {
                    let done = appointment.checklistItems.filter(\.isCompleted).count
                    HStack(spacing: 6) {
                        Image(systemName: "checklist")
                            .foregroundStyle(.teal)
                        Text("\(done)/\(appointment.checklistItems.count) prepared")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }

                if !appointment.notes.isEmpty {
                    Text(appointment.notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)

                    // AI actions for notes
                    if ai.isAvailable {
                        if let summary = summaries[appointment.id] {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("AI Summary", systemImage: "sparkles")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.teal)
                                Text(summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }

                        if let tasks = extractedTasks[appointment.id], !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Suggested Tasks", systemImage: "list.bullet.circle.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.teal)
                                ForEach(tasks, id: \.title) { task in
                                    Text("· \(task.title)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top, 2)
                        }

                        HStack(spacing: 12) {
                            Button {
                                asyncRun {
                                    let result = await ai.summarizeNotes(appointment.notes)
                                    if let result { summaries[appointment.id] = result }
                                }
                            } label: {
                                Label("Summarize", systemImage: "sparkles")
                            }

                            Button {
                                asyncRun {
                                    let result = await ai.extractTasks(from: appointment.notes)
                                    if !result.isEmpty { extractedTasks[appointment.id] = result }
                                }
                            } label: {
                                Label("Extract Tasks", systemImage: "list.bullet")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.teal)
                        .disabled(ai.isProcessing)
                        .padding(.top, 4)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
                .padding(.top, 4)
        }
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.teal.opacity(0.5))

            Text("No Appointments")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Schedule medical visits and checkups to stay on top of care")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingAddAppointment = true }) {
                Label("Add Appointment", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}

// MARK: - Add Appointment Sheet

struct AddAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]

    @State private var title = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Appointment Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date & Time", selection: $date)
                    TextField("Location", text: $location)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAppointment() }
                        .disabled(title.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveAppointment() {
        let appointment = Appointment(
            title: title,
            date: date,
            location: location,
            notes: notes
        )
        appointment.parentProfile = parentProfiles.first
        modelContext.insert(appointment)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [
            Appointment.self, ParentProfile.self,
            Task.self, FamilyMember.self,
            Document.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
