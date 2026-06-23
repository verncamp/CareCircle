//
//  NotificationManager.swift
//  CareCircle
//

import Foundation
import SwiftData
import UserNotifications

struct CareNotificationPreferences: Codable, Equatable {
    var appointment24h: Bool = true
    var appointment2h: Bool = true
    var appointment30m: Bool = true
    var taskDueEnabled: Bool = true
    var taskOverdueEnabled: Bool = true
    var taskDueHour: Int = 8
    var document60d: Bool = true
    var document30d: Bool = true
    var document7d: Bool = true
    var emergencyPacketCadenceDays: Int = 60
    var weeklyReadinessDigest: Bool = false

    private static let storageKey = "carecircle.notificationPreferences.v2"

    static func load() -> CareNotificationPreferences {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let prefs = try? JSONDecoder().decode(CareNotificationPreferences.self, from: data)
        else { return CareNotificationPreferences() }
        return prefs
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

enum NotificationManager {
    enum Keys {
        static let emergencyPacketLastGeneratedAt = "carecircle.emergencyPacketLastGeneratedAt"
        static let appointmentsEnabled = "notifications.appointmentsEnabled"
        static let tasksEnabled = "notifications.tasksEnabled"
        static let documentExpiryEnabled = "notifications.documentExpiryEnabled"
        static let emergencyPacketEnabled = "notifications.emergencyPacketEnabled"
        static let weeklyDigestEnabled = "notifications.weeklyDigestEnabled"
        static let appointmentLeadTime = "notifications.appointmentLeadTime"
        static let emergencyPacketIntervalDays = "notifications.emergencyPacketIntervalDays"
    }

    private static let prefix = "carecircle."

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func markEmergencyPacketGenerated(at date: Date = Date()) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.emergencyPacketLastGeneratedAt)
    }

    static func scheduleAll(
        appointments: [Appointment],
        tasks: [Task],
        documents: [Document],
        profile: ParentProfile? = nil,
        preferences: CareNotificationPreferences = .load()
    ) {
        cancelAll()
        appointments.forEach { scheduleAppointmentReminder(for: $0, preferences: preferences) }
        tasks.forEach { scheduleTaskReminder(for: $0, preferences: preferences) }
        documents.forEach { scheduleDocumentReminders(for: $0, preferences: preferences) }
        scheduleEmergencyPacketReminder(profile: profile, preferences: preferences)
        if preferences.weeklyReadinessDigest { scheduleWeeklyDigestReminder() }
    }

    static func scheduleAppointmentReminder(for appointment: Appointment) {
        scheduleAppointmentReminder(for: appointment, preferences: .load())
    }

    static func scheduleTaskReminder(for task: Task) {
        scheduleTaskReminder(for: task, preferences: .load())
    }

    static func scheduleDocumentExpiryReminder(for document: Document) {
        scheduleDocumentReminders(for: document, preferences: .load())
    }

    @MainActor
    static func resync(context: ModelContext, preferences: CareNotificationPreferences = .load()) {
        let appointments = (try? context.fetch(FetchDescriptor<Appointment>())) ?? []
        let tasks = (try? context.fetch(FetchDescriptor<Task>())) ?? []
        let documents = (try? context.fetch(FetchDescriptor<Document>())) ?? []
        let profiles = (try? context.fetch(FetchDescriptor<ParentProfile>())) ?? []
        scheduleAll(
            appointments: appointments,
            tasks: tasks,
            documents: documents,
            profile: profiles.first,
            preferences: preferences
        )
    }

    private static func scheduleAppointmentReminder(for appointment: Appointment, preferences: CareNotificationPreferences) {
        let windows: [(Bool, TimeInterval, String)] = [
            (preferences.appointment24h, 24 * 3600, "24h"),
            (preferences.appointment2h, 2 * 3600, "2h"),
            (preferences.appointment30m, 30 * 60, "30m")
        ]
        for window in windows where window.0 {
            let fireDate = appointment.date.addingTimeInterval(-window.1)
            let content = UNMutableNotificationContent()
            content.title = "Upcoming appointment"
            content.body = "\(appointment.title) starts in \(window.2)."
            content.sound = .default
            schedule(id: "\(prefix)appointment.\(appointment.id.uuidString).\(window.2)", at: fireDate, content: content)
        }
    }

    private static func scheduleTaskReminder(for task: Task, preferences: CareNotificationPreferences) {
        guard !task.isCompleted, let dueDate = task.dueDate else { return }
        if preferences.taskDueEnabled {
            var comp = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            comp.hour = preferences.taskDueHour
            comp.minute = 0
            let fire = Calendar.current.date(from: comp) ?? dueDate
            let content = UNMutableNotificationContent()
            content.title = "Task due today"
            content.body = task.title
            content.sound = .default
            schedule(id: "\(prefix)task.due.\(task.id.uuidString)", at: fire, content: content)
        }
        if preferences.taskOverdueEnabled, (task.priority == .high || task.priority == .urgent) {
            let fire = dueDate.addingTimeInterval(24 * 3600)
            let content = UNMutableNotificationContent()
            content.title = "Task overdue"
            content.body = "High-priority follow-up: \(task.title)"
            content.sound = .default
            schedule(id: "\(prefix)task.overdue.\(task.id.uuidString)", at: fire, content: content)
        }
    }

    private static func scheduleDocumentReminders(for document: Document, preferences: CareNotificationPreferences) {
        guard let expiryDate = document.expiryDate else { return }
        let windows: [(Bool, Int, String)] = [
            (preferences.document60d, 60, "60d"),
            (preferences.document30d, 30, "30d"),
            (preferences.document7d, 7, "7d")
        ]
        for window in windows where window.0 {
            guard let fireDate = Calendar.current.date(byAdding: .day, value: -window.1, to: expiryDate) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Document expiry reminder"
            content.body = "\(document.title) expires in \(window.1) days."
            content.sound = .default
            schedule(id: "\(prefix)document.expiry.\(document.id.uuidString).\(window.2)", at: fireDate, content: content)
        }
    }

    private static func scheduleEmergencyPacketReminder(profile: ParentProfile?, preferences: CareNotificationPreferences) {
        let lastGenerated = UserDefaults.standard.double(forKey: Keys.emergencyPacketLastGeneratedAt)
        let baselineDate = lastGenerated > 0 ? Date(timeIntervalSince1970: lastGenerated) : Date()
        guard let nextDate = Calendar.current.date(byAdding: .day, value: preferences.emergencyPacketCadenceDays, to: baselineDate) else { return }
        let name = profile?.name.isEmpty == false ? profile?.name ?? "your parent" : "your parent"
        let content = UNMutableNotificationContent()
        content.title = "Emergency packet refresh"
        content.body = "Review and refresh emergency information for \(name)."
        content.sound = .default
        schedule(id: "\(prefix)emergency.packet.stale", at: nextDate, content: content)
    }

    private static func scheduleWeeklyDigestReminder() {
        var components = DateComponents()
        components.weekday = 2
        components.hour = 9
        components.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "Weekly readiness digest"
        content.body = "Review tasks, appointments, and critical document expiries."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "\(prefix)weekly.readiness.digest",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func schedule(id: String, at date: Date, content: UNNotificationContent) {
        guard date > Date() else { return }
        let comp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
