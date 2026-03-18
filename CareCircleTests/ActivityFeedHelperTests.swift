//
//  ActivityFeedHelperTests.swift
//  CareCircleTests
//

import XCTest
import SwiftData
@testable import CareCircle

final class ActivityFeedHelperTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        container = try! ModelContainer(
            for: ParentProfile.self, Appointment.self, Task.self,
                 Document.self, FamilyMember.self, Expense.self,
                 ExpenseAccount.self, UpdateFeedItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    @MainActor
    func testLogAppointmentAdded() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let appt = Appointment(title: "Cardiology", date: Date(), location: "City Hospital")
        appt.parentProfile = profile
        context.insert(appt)
        try context.save()

        ActivityFeedHelper.logAppointmentAdded(appt, by: "Alice", profile: profile, context: context)

        let descriptor = FetchDescriptor<UpdateFeedItem>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.type, .appointmentAdded)
        XCTAssertEqual(items.first?.authorName, "Alice")
        XCTAssertTrue(items.first?.message.contains("Cardiology") ?? false)
        XCTAssertEqual(items.first?.parentProfile?.id, profile.id)
    }

    @MainActor
    func testLogTaskCompleted() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let task = Task(title: "Refill prescriptions")
        task.parentProfile = profile
        context.insert(task)
        try context.save()

        ActivityFeedHelper.logTaskCompleted(task, by: "Bob", profile: profile, context: context)

        let descriptor = FetchDescriptor<UpdateFeedItem>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.type, .taskCompleted)
        XCTAssertTrue(items.first?.message.contains("Refill prescriptions") ?? false)
    }

    @MainActor
    func testLogDocumentAdded() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let doc = Document(title: "Blood Work Results", category: .lab)
        doc.parentProfile = profile
        context.insert(doc)
        try context.save()

        ActivityFeedHelper.logDocumentAdded(doc, by: "Alice", profile: profile, context: context)

        let descriptor = FetchDescriptor<UpdateFeedItem>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.type, .documentAdded)
        XCTAssertTrue(items.first?.message.contains("Blood Work Results") ?? false)
        XCTAssertTrue(items.first?.message.contains("lab results") ?? false)
    }

    @MainActor
    func testLogExpenseAdded() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let expense = Expense(title: "Physical Therapy", amount: 150, category: .medical)
        expense.parentProfile = profile
        context.insert(expense)
        try context.save()

        ActivityFeedHelper.logExpenseAdded(expense, by: "Bob", profile: profile, context: context)

        let descriptor = FetchDescriptor<UpdateFeedItem>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.type, .expenseAdded)
        XCTAssertTrue(items.first?.message.contains("Physical Therapy") ?? false)
    }

    @MainActor
    func testLogNote() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)
        try context.save()

        ActivityFeedHelper.logNote("Mom had a great day", by: "Alice", profile: profile, context: context)

        let descriptor = FetchDescriptor<UpdateFeedItem>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.type, .note)
        XCTAssertEqual(items.first?.message, "Mom had a great day")
    }

    @MainActor
    func testMultipleLogsAccumulate() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)
        try context.save()

        ActivityFeedHelper.logNote("Note 1", by: "A", profile: profile, context: context)
        ActivityFeedHelper.logNote("Note 2", by: "B", profile: profile, context: context)
        ActivityFeedHelper.logNote("Note 3", by: "C", profile: profile, context: context)

        let descriptor = FetchDescriptor<UpdateFeedItem>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 3)
    }
}
