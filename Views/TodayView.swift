//
//  TodayView.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    
    var activeProfile: ParentProfile? {
        parentProfiles.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = activeProfile {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(profile.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button(action: {
                                    // Emergency action
                                }) {
                                    Text("Emergency")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.red, in: Capsule())
                                }
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(profile.statusMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(Date().formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Next Appointment
                        if let nextAppt = nextAppointment(from: profile) {
                            NextAppointmentCard(appointment: nextAppt)
                        }
                        
                        // Critical Tasks
                        CriticalTasksCard(tasks: criticalTasks(from: profile))
                        
                        // Recent Updates
                        RecentUpdatesCard(updates: recentUpdates(from: profile))
                        
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("No Parent Profile")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Create a parent profile to get started")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button("Create Profile") {
                                createSampleProfile()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(40)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
        }
    }
    
    // MARK: - Helper Functions
    
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
            .prefix(3)
            .map { $0 }
    }
    
    func recentUpdates(from profile: ParentProfile) -> [UpdateFeedItem] {
        profile.updateFeedItems
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            .map { $0 }
    }
    
    func createSampleProfile() {
        let profile = ParentProfile(name: "Mom Alvarez")
        modelContext.insert(profile)
        
        // Sample appointment
        let appointment = Appointment(
            title: "Cardiology Follow-up",
            date: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
            location: "St. Mary's Clinic",
            checklistItems: [
                ChecklistItem(title: "Insurance card", isCompleted: true),
                ChecklistItem(title: "Medication list", isCompleted: true),
                ChecklistItem(title: "Bring last lab report", isCompleted: false)
            ]
        )
        appointment.parentProfile = profile
        modelContext.insert(appointment)
        
        // Sample tasks
        let task1 = Task(title: "Refill blood pressure meds", priority: .urgent)
        task1.parentProfile = profile
        modelContext.insert(task1)
        
        let task2 = Task(title: "Upload discharge summary", priority: .high)
        task2.parentProfile = profile
        modelContext.insert(task2)
        
        let task3 = Task(title: "Confirm ride for Thursday", priority: .high)
        task3.parentProfile = profile
        modelContext.insert(task3)
        
        // Sample updates
        let update1 = UpdateFeedItem(type: .note, message: "Vitals looked normal.", authorName: "Sarah")
        update1.parentProfile = profile
        modelContext.insert(update1)
        
        let update2 = UpdateFeedItem(type: .documentAdded, message: "Scanned lab results.", authorName: "You")
        update2.parentProfile = profile
        modelContext.insert(update2)
        
        try? modelContext.save()
    }
}

// MARK: - Component Views

struct NextAppointmentCard: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next up")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.date.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(appointment.title)
                        .font(.body)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Open")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
            
            if !appointment.checklistItems.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.secondary)
                    Text("\(appointment.checklistItems.filter { $0.isCompleted }.count)/\(appointment.checklistItems.count) items ready")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CriticalTasksCard: View {
    let tasks: [Task]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Critical tasks")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("See all") {}
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            
            if tasks.isEmpty {
                Text("No critical tasks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TaskRow: View {
    let task: Task
    @State private var isCompleted: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                isCompleted.toggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            
            Text(task.title)
                .font(.body)
            
            Spacer()
        }
    }
}

struct RecentUpdatesCard: View {
    let updates: [UpdateFeedItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent updates")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            
            if updates.isEmpty {
                Text("No recent updates")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(updates) { update in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(update.authorName): "\(update.message)"")
                                    .font(.subheadline)
                                Text(update.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [ParentProfile.self, Appointment.self, Task.self, UpdateFeedItem.self], inMemory: true)
}
