//
//  ActivityFeedHelper.swift
//  CareCircle
//
//  Automatically creates UpdateFeedItem entries when care actions occur.
//

import SwiftData

@MainActor
struct ActivityFeedHelper {

    static func log(
        type: UpdateType,
        message: String,
        authorName: String,
        profile: ParentProfile?,
        context: ModelContext
    ) {
        let item = UpdateFeedItem(
            type: type,
            message: message,
            authorName: authorName
        )
        item.parentProfile = profile
        context.insert(item)
        try? context.save()
    }

    // MARK: - Convenience Methods

    static func logAppointmentAdded(
        _ appointment: Appointment,
        by authorName: String,
        profile: ParentProfile?,
        context: ModelContext
    ) {
        let dateStr = appointment.date.formatted(date: .abbreviated, time: .shortened)
        log(
            type: .appointmentAdded,
            message: "Scheduled \(appointment.title) for \(dateStr)",
            authorName: authorName,
            profile: profile,
            context: context
        )
    }

    static func logTaskCompleted(
        _ task: Task,
        by authorName: String,
        profile: ParentProfile?,
        context: ModelContext
    ) {
        log(
            type: .taskCompleted,
            message: "Completed task: \(task.title)",
            authorName: authorName,
            profile: profile,
            context: context
        )
    }

    static func logDocumentAdded(
        _ document: Document,
        by authorName: String,
        profile: ParentProfile?,
        context: ModelContext
    ) {
        log(
            type: .documentAdded,
            message: "Added \(document.category.rawValue.lowercased()) document: \(document.title)",
            authorName: authorName,
            profile: profile,
            context: context
        )
    }

    static func logExpenseAdded(
        _ expense: Expense,
        by authorName: String,
        profile: ParentProfile?,
        context: ModelContext
    ) {
        let amount = formatCurrency(expense.amount)
        log(
            type: .expenseAdded,
            message: "Recorded \(amount) expense: \(expense.title)",
            authorName: authorName,
            profile: profile,
            context: context
        )
    }

    static func logNote(
        _ message: String,
        by authorName: String,
        profile: ParentProfile?,
        context: ModelContext
    ) {
        log(
            type: .note,
            message: message,
            authorName: authorName,
            profile: profile,
            context: context
        )
    }
}
