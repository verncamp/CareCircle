//
//  NotificationManager.swift
//  CareCircle
//
//  Local notifications for upcoming appointments and overdue tasks.
//

import UserNotifications
import SwiftData

@MainActor
struct NotificationManager {

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Appointment Reminders

    /// Schedule a notification 1 hour before an appointment.
    static func scheduleAppointmentReminder(for appointment: Appointment) {
        let center = UNUserNotificationCenter.current()

        // Remove any existing notification for this appointment
        let identifier = "appointment-\(appointment.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Don't schedule for past appointments
        guard appointment.date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Appointment"
        content.body = "\(appointment.title) in 1 hour"
        if !appointment.location.isEmpty {
            content.body += " at \(appointment.location)"
        }
        content.sound = .default
        content.categoryIdentifier = "appointment"

        // Checklist reminder
        let incomplete = appointment.checklistItems.filter { !$0.isCompleted }.count
        if incomplete > 0 {
            content.subtitle = "\(incomplete) checklist item\(incomplete == 1 ? "" : "s") still to prepare"
        }

        // Trigger 1 hour before
        let triggerDate = appointment.date.addingTimeInterval(-3600)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Task Due Reminders

    /// Schedule a notification on the morning a task is due.
    static func scheduleTaskReminder(for task: Task) {
        let center = UNUserNotificationCenter.current()

        let identifier = "task-\(task.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard !task.isCompleted, let dueDate = task.dueDate, dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Due Today"
        content.body = task.title
        if let assignee = task.assignedTo {
            content.subtitle = "Assigned to \(assignee.name)"
        }
        content.sound = .default
        content.categoryIdentifier = "task"

        // Trigger at 8 AM on the due date
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Bulk Schedule

    /// Re-schedule all notifications for active appointments and tasks.
    static func scheduleAll(appointments: [Appointment], tasks: [Task]) {
        // Clear existing
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Appointments in the future
        for appointment in appointments where appointment.date > Date() {
            scheduleAppointmentReminder(for: appointment)
        }

        // Tasks with due dates
        for task in tasks where !task.isCompleted {
            scheduleTaskReminder(for: task)
        }
    }

    /// Remove all CareCircle notifications.
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
