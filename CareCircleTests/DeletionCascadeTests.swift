//
//  DeletionCascadeTests.swift
//  CareCircleTests
//
//  Tests that cascade deletion and cleanup work correctly.
//

import XCTest
import SwiftData
@testable import CareCircle

final class DeletionCascadeTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        container = try! ModelContainer(
            for: ParentProfile.self, Appointment.self, Task.self,
                 Document.self, FamilyMember.self, Expense.self,
                 ExpenseAccount.self, UpdateFeedItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Profile cascade deletion

    @MainActor
    func testDeletingProfileCascadesToAppointments() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let appt = Appointment(title: "Checkup", date: Date())
        appt.parentProfile = profile
        context.insert(appt)
        try context.save()

        XCTAssertEqual(profile.appointments.count, 1)

        context.delete(profile)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Appointment>())
        XCTAssertTrue(remaining.isEmpty, "Appointments should be deleted when profile is deleted")
    }

    @MainActor
    func testDeletingProfileCascadesToTasks() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let task = Task(title: "Pick up meds", priority: .high)
        task.parentProfile = profile
        context.insert(task)
        try context.save()

        context.delete(profile)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Task>())
        XCTAssertTrue(remaining.isEmpty, "Tasks should be deleted when profile is deleted")
    }

    @MainActor
    func testDeletingProfileCascadesToDocuments() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let doc = Document(title: "Insurance", category: .insurance)
        doc.parentProfile = profile
        context.insert(doc)
        try context.save()

        context.delete(profile)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Document>())
        XCTAssertTrue(remaining.isEmpty, "Documents should be deleted when profile is deleted")
    }

    @MainActor
    func testDeletingProfileCascadesToFamilyMembers() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let member = FamilyMember(name: "Alice", role: .medicalAdmin)
        member.parentProfile = profile
        context.insert(member)
        try context.save()

        context.delete(profile)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<FamilyMember>())
        XCTAssertTrue(remaining.isEmpty, "Family members should be deleted when profile is deleted")
    }

    // MARK: - Family member cleanup

    @MainActor
    func testDeletingFamilyMemberNullifiesTaskAssignment() throws {
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

        XCTAssertEqual(task.assignedTo?.name, "Alice")

        context.delete(member)
        try context.save()

        // Task should still exist but be unassigned
        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertNil(tasks.first?.assignedTo, "Task should be unassigned after member deletion")
    }

    @MainActor
    func testDeletingFamilyMemberWithExpenseAccount() throws {
        let member = FamilyMember(name: "Bob", role: .bills)
        context.insert(member)

        let account = ExpenseAccount()
        account.familyMember = member
        member.expenseAccount = account
        account.contribute(amount: 100)
        context.insert(account)
        try context.save()

        // Simulate SettingsView deleteMember behavior
        if let acct = member.expenseAccount {
            context.delete(acct)
        }
        context.delete(member)
        try context.save()

        let members = try context.fetch(FetchDescriptor<FamilyMember>())
        let accounts = try context.fetch(FetchDescriptor<ExpenseAccount>())
        XCTAssertTrue(members.isEmpty)
        XCTAssertTrue(accounts.isEmpty, "ExpenseAccount should be deleted with member")
    }
}
