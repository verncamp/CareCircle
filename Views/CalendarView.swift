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
    @State private var searchText = ""
    @State private var showPast = false

    var upcomingAppointments: [Appointment] {
        let upcoming = appointments.filter { $0.date > Date() }
        if searchText.isEmpty { return upcoming }
        return upcoming.filter { matchesSearch($0) }
    }

    var pastAppointments: [Appointment] {
        let past = appointments.filter { $0.date <= Date() }.reversed()
        if searchText.isEmpty { return Array(past) }
        return past.filter { matchesSearch($0) }
    }

    private func matchesSearch(_ appt: Appointment) -> Bool {
        appt.title.localizedCaseInsensitiveContains(searchText) ||
        appt.location.localizedCaseInsensitiveContains(searchText) ||
        appt.notes.localizedCaseInsensitiveContains(searchText)
    }

    var groupedByDate: [(key: String, appointments: [Appointment])] {
        let grouped = Dictionary(grouping: upcomingAppointments) { appt in
            appt.date.formatted(date: .complete, time: .omitted)
        }
        return grouped
            .map { (key: $0.key, appointments: $0.value) }
            .sorted { ($0.appointments.first?.date ?? .distantPast) < ($1.appointments.first?.date ?? .distantPast) }
    }

    var groupedPast: [(key: String, appointments: [Appointment])] {
        let grouped = Dictionary(grouping: pastAppointments) { appt in
            appt.date.formatted(date: .complete, time: .omitted)
        }
        return grouped
            .map { (key: $0.key, appointments: $0.value) }
            .sorted { ($0.appointments.first?.date ?? .distantPast) > ($1.appointments.first?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Upcoming
                    if upcomingAppointments.isEmpty && !showPast {
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

                    // Past Appointments
                    if !pastAppointments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation { showPast.toggle() }
                            } label: {
                                HStack(spacing: 6) {
                                    SectionHeader(title: "Past Appointments")
                                    Spacer()
                                    Text("\(pastAppointments.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: showPast ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            if showPast {
                                ForEach(groupedPast, id: \.key) { group in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(group.key)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.tertiary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)

                                        ForEach(group.appointments) { appointment in
                                            appointmentCard(appointment, isPast: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .adaptiveWidth()
            }
            .searchable(text: $searchText, prompt: "Search appointments")
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

    private func appointmentCard(_ appointment: Appointment, isPast: Bool = false) -> some View {
        NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
            HStack(alignment: .top, spacing: 14) {
                Text(appointment.date.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.teal)
                    .frame(width: 64, alignment: .trailing)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.teal.opacity(0.3))
                    .frame(width: 3)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(appointment.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

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
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
                    .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
        .glassCard()
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(appointment)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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

    @Query private var familyMembers: [FamilyMember]

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
        NotificationManager.scheduleAppointmentReminder(for: appointment)

        let author = familyMembers.first(where: \.isCurrentUser)?.name ?? "Someone"
        ActivityFeedHelper.logAppointmentAdded(appointment, by: author, profile: parentProfiles.first, context: modelContext)
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
