//
//  CalendarView.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appointments: [Appointment]
    @State private var showingAddAppointment = false
    
    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if upcomingAppointments.isEmpty {
                    ContentUnavailableView(
                        "No Appointments",
                        systemImage: "calendar",
                        description: Text("Add appointments to keep track of medical visits and checkups")
                    )
                } else {
                    ForEach(upcomingAppointments) { appointment in
                        AppointmentListRow(appointment: appointment)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddAppointment = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView()
            }
        }
    }
}

struct AppointmentListRow: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appointment.title)
                .font(.headline)
            
            HStack {
                Label(
                    appointment.date.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                if !appointment.location.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(appointment.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAppointment()
                    }
                    .disabled(title.isEmpty)
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
        .modelContainer(for: [Appointment.self, ParentProfile.self], inMemory: true)
}
