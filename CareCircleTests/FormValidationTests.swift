//
//  FormValidationTests.swift
//  CareCircleTests
//
//  Tests for edge cases in data creation and model behavior.
//

import XCTest
import SwiftData
@testable import CareCircle

final class FormValidationTests: XCTestCase {

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

    // MARK: - Empty/whitespace fields

    @MainActor
    func testEmptyTitleTaskCanBeSaved() throws {
        // SwiftData allows empty strings; the UI guards with .disabled
        let task = Task(title: "", priority: .normal)
        context.insert(task)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "")
    }

    @MainActor
    func testExpenseWithZeroAmount() throws {
        let expense = Expense(title: "Free sample", amount: 0, category: .medication)
        context.insert(expense)
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertEqual(expenses.count, 1)
        XCTAssertEqual(expenses.first?.amount, 0)
    }

    @MainActor
    func testExpenseWithLargeDecimalAmount() throws {
        let largeAmount = Decimal(string: "125000.99")!
        let expense = Expense(title: "Surgery", amount: largeAmount, category: .medical)
        context.insert(expense)
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertEqual(expenses.first?.amount, largeAmount)
    }

    @MainActor
    func testDocumentWithAllCategories() throws {
        for category in DocumentCategory.allCases {
            let doc = Document(title: "Test \(category.rawValue)", category: category)
            context.insert(doc)
        }
        try context.save()

        let docs = try context.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(docs.count, DocumentCategory.allCases.count)
    }

    @MainActor
    func testTaskPrioritySortOrder() {
        // Verify sortOrder is correctly ordered: urgent < high < normal < low
        XCTAssertLessThan(TaskPriority.urgent.sortOrder, TaskPriority.high.sortOrder)
        XCTAssertLessThan(TaskPriority.high.sortOrder, TaskPriority.normal.sortOrder)
        XCTAssertLessThan(TaskPriority.normal.sortOrder, TaskPriority.low.sortOrder)
    }

    @MainActor
    func testChecklistItemToggle() {
        var item = ChecklistItem(title: "Bring insurance card")
        XCTAssertFalse(item.isCompleted)

        item.isCompleted = true
        XCTAssertTrue(item.isCompleted)

        item.isCompleted = false
        XCTAssertFalse(item.isCompleted)
    }

    @MainActor
    func testMedicationCodable() throws {
        let med = Medication(name: "Lisinopril", dosage: "10mg", frequency: "Daily", prescribedBy: "Dr. Chen")

        let data = try JSONEncoder().encode(med)
        let decoded = try JSONDecoder().decode(Medication.self, from: data)

        XCTAssertEqual(decoded.name, "Lisinopril")
        XCTAssertEqual(decoded.dosage, "10mg")
        XCTAssertEqual(decoded.frequency, "Daily")
        XCTAssertEqual(decoded.prescribedBy, "Dr. Chen")
    }

    @MainActor
    func testMultipleFamilyMembersOnlyOneCurrentUser() throws {
        let profile = ParentProfile(name: "Mom")
        context.insert(profile)

        let alice = FamilyMember(name: "Alice", role: .medicalAdmin, isCurrentUser: true)
        alice.parentProfile = profile
        context.insert(alice)

        let bob = FamilyMember(name: "Bob", role: .bills, isCurrentUser: false)
        bob.parentProfile = profile
        context.insert(bob)

        let charlie = FamilyMember(name: "Charlie", role: .transportation, isCurrentUser: false)
        charlie.parentProfile = profile
        context.insert(charlie)

        try context.save()

        let members = try context.fetch(FetchDescriptor<FamilyMember>())
        let currentUsers = members.filter(\.isCurrentUser)
        XCTAssertEqual(currentUsers.count, 1)
        XCTAssertEqual(currentUsers.first?.name, "Alice")
    }
}
