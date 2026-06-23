//
//  NotificationSettingsView.swift
//  CareCircle
//
//  Manage local reminder categories and timing.
//

import SwiftData
import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Query private var tasks: [Task]
    @Query private var documents: [Document]
    @Query private var profiles: [ParentProfile]

    @AppStorage(NotificationManager.Keys.appointmentsEnabled) private var appointmentsEnabled = true
    @AppStorage(NotificationManager.Keys.tasksEnabled) private var tasksEnabled = true
    @AppStorage(NotificationManager.Keys.documentExpiryEnabled) private var documentExpiryEnabled = true
    @AppStorage(NotificationManager.Keys.emergencyPacketEnabled) private var emergencyPacketEnabled = true
    @AppStorage(NotificationManager.Keys.weeklyDigestEnabled) private var weeklyDigestEnabled = false
    @AppStorage(NotificationManager.Keys.appointmentLeadTime) private var appointmentLeadTimeMinutes = 120
    @AppStorage(NotificationManager.Keys.emergencyPacketIntervalDays) private var emergencyPacketIntervalDays = 60

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingCount = 0
    @State private var isLoading = false

    private var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    private var currentPreferences: CareNotificationPreferences {
        CareNotificationPreferences(
            appointment24h: appointmentsEnabled && appointmentLeadTimeMinutes == 1440,
            appointment2h: appointmentsEnabled && appointmentLeadTimeMinutes == 120,
            appointment30m: appointmentsEnabled && appointmentLeadTimeMinutes == 30,
            taskDueEnabled: tasksEnabled,
            taskOverdueEnabled: tasksEnabled,
            taskDueHour: 8,
            document60d: documentExpiryEnabled,
            document30d: documentExpiryEnabled,
            document7d: documentExpiryEnabled,
            emergencyPacketCadenceDays: emergencyPacketEnabled ? emergencyPacketIntervalDays : 3650,
            weeklyReadinessDigest: weeklyDigestEnabled
        )
    }

    var body: some View {
        List {
            statusSection

            if isAuthorized {
                categoriesSection
                timingSection
                activeSection
                actionsSection
            }

            infoSection
        }
        .navigationTitle("Notifications")
        .onChange(of: appointmentsEnabled) { _, _ in reschedule() }
        .onChange(of: tasksEnabled) { _, _ in reschedule() }
        .onChange(of: documentExpiryEnabled) { _, _ in reschedule() }
        .onChange(of: emergencyPacketEnabled) { _, _ in reschedule() }
        .onChange(of: weeklyDigestEnabled) { _, _ in reschedule() }
        .onChange(of: appointmentLeadTimeMinutes) { _, _ in reschedule() }
        .onChange(of: emergencyPacketIntervalDays) { _, _ in reschedule() }
        .task {
            migrateAppointmentLeadTimeIfNeeded()
            await checkStatus()
        }
    }

    private var statusSection: some View {
        Section("Status") {
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
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }

            if authorizationStatus == .notDetermined {
                Button("Enable Notifications") {
                    asyncRun { @MainActor in
                        _ = await NotificationManager.requestPermission()
                        await checkStatus()
                    }
                }
                .foregroundStyle(.careTint)
            }
        }
    }

    private var categoriesSection: some View {
        Section("Reminder Categories") {
            Toggle("Appointments", isOn: $appointmentsEnabled)
            Toggle("Tasks", isOn: $tasksEnabled)
            Toggle("Document Expiry", isOn: $documentExpiryEnabled)
            Toggle("Emergency Packet Refresh", isOn: $emergencyPacketEnabled)
            Toggle("Weekly Readiness Digest", isOn: $weeklyDigestEnabled)
        }
    }

    private var timingSection: some View {
        Section("Timing") {
            Picker("Appointment lead time", selection: $appointmentLeadTimeMinutes) {
                Text("30 minutes").tag(30)
                Text("2 hours").tag(120)
                Text("24 hours").tag(1440)
            }

            Picker("Emergency packet interval", selection: $emergencyPacketIntervalDays) {
                Text("30 days").tag(30)
                Text("60 days").tag(60)
                Text("90 days").tag(90)
            }
        }
    }

    private var activeSection: some View {
        Section("Active Reminders") {
            HStack {
                Label("Scheduled", systemImage: "clock.badge")
                Spacer()
                Text("\(pendingCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack {
                Label("Upcoming Appointments", systemImage: "calendar")
                Spacer()
                Text("\(appointments.filter { $0.date > Date() }.count)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Open Tasks", systemImage: "checklist")
                Spacer()
                Text("\(tasks.filter { !$0.isCompleted }.count)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Expiring Docs (60d)", systemImage: "doc.badge.clock")
                Spacer()
                Text("\(documents.filter(isExpiringWithin60Days).count)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                reschedule()
            } label: {
                HStack {
                    Label("Reschedule All Reminders", systemImage: "arrow.clockwise")
                    if isLoading {
                        Spacer()
                        ProgressView().controlSize(.small)
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
        }
    }

    private var infoSection: some View {
        Section("How It Works") {
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "calendar.badge.clock", text: "Appointment reminders use your selected lead time")
                infoRow(icon: "checklist", text: "Task reminders include overdue follow-up for critical items")
                infoRow(icon: "doc.badge.clock", text: "Document expiry reminders notify at 60/30/7 days")
                infoRow(icon: "iphone", text: "All reminders are scheduled locally on this iPhone")
            }
            .padding(.vertical, 4)
        }
    }

    private func reschedule() {
        isLoading = true
        let preferences = currentPreferences
        preferences.save()
        NotificationManager.scheduleAll(
            appointments: appointments,
            tasks: tasks,
            documents: documents,
            profile: profiles.first,
            preferences: preferences
        )
        asyncRun { @MainActor in
            await checkStatus()
            isLoading = false
        }
    }

    private func migrateAppointmentLeadTimeIfNeeded() {
        switch appointmentLeadTimeMinutes {
        case 1:
            appointmentLeadTimeMinutes = 30
        case 2:
            appointmentLeadTimeMinutes = 120
        case 24:
            appointmentLeadTimeMinutes = 1440
        default:
            break
        }
    }

    private func isExpiringWithin60Days(_ document: Document) -> Bool {
        guard let expiry = document.expiryDate else { return false }
        let cutoff = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? .distantFuture
        return expiry >= Date() && expiry <= cutoff
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.careTint)
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
        pendingCount = pending.filter { $0.identifier.hasPrefix("carecircle.") }.count
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
