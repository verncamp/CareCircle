//
//  ModelRelationshipTests.swift
//  CareCircleTests
//

import XCTest
import SwiftData
@testable import CareCircle

final class ModelRelationshipTests: XCTestCase {

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

    // MARK: - ParentProfile relationships

    @MainActor
    func testProfileOwnsAppointments() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let appt = Appointment(title: "Checkup", date: Date())
        appt.parentProfile = profile
        context.insert(appt)
        try context.save()

        XCTAssertEqual(profile.appointments.count, 1)
        XCTAssertEqual(profile.appointments.first?.title, "Checkup")
    }

    @MainActor
    func testProfileOwnsTasks() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let task = Task(title: "Pick up meds", priority: .high)
        task.parentProfile = profile
        context.insert(task)
        try context.save()

        XCTAssertEqual(profile.tasks.count, 1)
        XCTAssertEqual(profile.tasks.first?.title, "Pick up meds")
    }

    @MainActor
    func testProfileOwnsDocuments() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let doc = Document(title: "Insurance Card", category: .insurance)
        doc.parentProfile = profile
        context.insert(doc)
        try context.save()

        XCTAssertEqual(profile.documents.count, 1)
        XCTAssertEqual(profile.documents.first?.category, .insurance)
    }

    @MainActor
    func testProfileOwnsFamilyMembers() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let member = FamilyMember(name: "Alice", role: .medicalAdmin, isCurrentUser: true)
        member.parentProfile = profile
        context.insert(member)
        try context.save()

        XCTAssertEqual(profile.familyMembers.count, 1)
        XCTAssertTrue(profile.familyMembers.first?.isCurrentUser ?? false)
    }

    @MainActor
    func testFamilyMemberHasExpenseAccount() throws {
        let member = FamilyMember(name: "Bob", role: .bills)
        context.insert(member)

        let account = ExpenseAccount()
        account.familyMember = member
        member.expenseAccount = account
        context.insert(account)
        try context.save()

        XCTAssertNotNil(member.expenseAccount)
        XCTAssertEqual(member.expenseAccount?.balance, 0)
    }

    @MainActor
    func testTaskAssignedToFamilyMember() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let member = FamilyMember(name: "Alice", role: .dailyCheckIns)
        member.parentProfile = profile
        context.insert(member)

        let task = Task(title: "Morning check-in")
        task.parentProfile = profile
        task.assignedTo = member
        context.insert(task)
        try context.save()

        XCTAssertEqual(member.assignedTasks.count, 1)
        XCTAssertEqual(task.assignedTo?.name, "Alice")
    }

    @MainActor
    func testExpensePaidByMember() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let member = FamilyMember(name: "Bob", role: .bills)
        member.parentProfile = profile
        context.insert(member)

        let expense = Expense(title: "Pharmacy", amount: 45.50, category: .medication)
        expense.parentProfile = profile
        expense.paidBy = member
        context.insert(expense)
        try context.save()

        XCTAssertEqual(expense.paidBy?.name, "Bob")
        XCTAssertEqual(profile.expenses.count, 1)
    }

    @MainActor
    func testUpdateFeedItemLinkedToProfile() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let item = UpdateFeedItem(type: .note, message: "All good today", authorName: "Alice")
        item.parentProfile = profile
        context.insert(item)
        try context.save()

        XCTAssertEqual(profile.updateFeedItems.count, 1)
        XCTAssertEqual(profile.updateFeedItems.first?.type, .note)
    }
}
