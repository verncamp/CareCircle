//
//  NotificationSettingsView.swift
//  CareCircle
//
//  Manage notification preferences for appointments and tasks.
//

import SwiftUI
import SwiftData
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Query private var tasks: [Task]

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingCount = 0
    @State private var isLoading = false

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    var body: some View {
        List {
            // Status section
            Section {
                HStack(spacing: 14) {
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundStyle(statusColor)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notification Status")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if authorizationStatus == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                }

                if authorizationStatus == .notDetermined {
                    Button {
                        asyncRun { @MainActor in
                            _ = await NotificationManager.requestPermission()
                            await checkStatus()
                        }
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.badge")
                            .foregroundStyle(.teal)
                    }
                }
            } header: {
                Text("Status")
            } footer: {
                if authorizationStatus == .denied {
                    Text("Notifications were denied. Open Settings to allow CareCircle notifications.")
                }
            }

            // Active reminders
            if isAuthorized {
                Section {
                    HStack {
                        Label("Scheduled Reminders", systemImage: "clock.badge")
                        Spacer()
                        Text("\(pendingCount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.teal)
                    }

                    let futureAppointments = appointments.filter { $0.date > Date() }.count
                    let tasksWithDue = tasks.filter { !$0.isCompleted && $0.dueDate != nil }.count

                    HStack {
                        Label("Upcoming Appointments", systemImage: "calendar")
                        Spacer()
                        Text("\(futureAppointments)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Tasks with Due Dates", systemImage: "checklist")
                        Spacer()
                        Text("\(tasksWithDue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Active Reminders")
                }

                // Actions
                Section {
                    Button {
                        isLoading = true
                        NotificationManager.scheduleAll(
                            appointments: appointments,
                            tasks: tasks
                        )
                        asyncRun { @MainActor in
                            await checkStatus()
                            isLoading = false
                        }
                    } label: {
                        HStack {
                            Label("Reschedule All Reminders", systemImage: "arrow.clockwise")
                                .foregroundStyle(.teal)
                            if isLoading {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isLoading)

                    Button(role: .destructive) {
                        NotificationManager.cancelAll()
                        asyncRun { @MainActor in await checkStatus() }
                    } label: {
                        Label("Clear All Reminders", systemImage: "bell.slash")
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Reschedule refreshes all appointment (1 hour before) and task (8 AM on due date) reminders.")
                }
            }

            // Info section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(icon: "calendar.badge.clock", text: "Appointment reminders fire 1 hour before")
                    infoRow(icon: "checklist", text: "Task reminders fire at 8:00 AM on due date")
                    infoRow(icon: "iphone", text: "Reminders are local to this device")
                }
                .padding(.vertical, 4)
            } header: {
                Text("How It Works")
            }
        }
        .navigationTitle("Notifications")
        .task {
            await checkStatus()
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.teal)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingCount = pending.count
    }

    private var statusIcon: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "bell.badge.fill"
        case .denied: return "bell.slash.fill"
        case .notDetermined: return "bell.fill"
        @unknown default: return "bell.fill"
        }
    }

    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .secondary
        @unknown default: return .secondary
        }
    }

    private var statusDescription: String {
        switch authorizationStatus {
        case .authorized: return "Notifications enabled"
        case .provisional: return "Provisional notifications enabled"
        case .ephemeral: return "Ephemeral notifications enabled"
        case .denied: return "Notifications denied"
        case .notDetermined: return "Not yet configured"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .modelContainer(for: [
        Appointment.self, Task.self,
        ParentProfile.self, FamilyMember.self,
        Document.self, Expense.self,
        ExpenseAccount.self, UpdateFeedItem.self
    ], inMemory: true)
}
