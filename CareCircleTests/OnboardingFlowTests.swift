//
//  OnboardingFlowTests.swift
//  CareCircleTests
//
//  Tests that onboarding creates the correct data structures.
//

import XCTest
import SwiftData
@testable import CareCircle

final class OnboardingFlowTests: XCTestCase {

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

    // MARK: - Simulated onboarding data creation

    @MainActor
    func testOnboardingCreatesProfileMemberAndAccount() throws {
        // Simulate what OnboardingView.createProfile() does
        let profile = ParentProfile(
            name: "Mom",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -75, to: Date()),
            bloodType: "O+",
            allergies: "Penicillin",
            primaryPhysician: "Dr. Smith"
        )
        context.insert(profile)

        let member = FamilyMember(
            name: "Alice",
            role: .medicalAdmin,
            email: "alice@example.com",
            isCurrentUser: true
        )
        member.parentProfile = profile
        context.insert(member)

        let account = ExpenseAccount()
        account.familyMember = member
        member.expenseAccount = account
        context.insert(account)

        try context.save()

        // Verify profile
        XCTAssertEqual(profile.name, "Mom")
        XCTAssertEqual(profile.bloodType, "O+")
        XCTAssertEqual(profile.allergies, "Penicillin")
        XCTAssertEqual(profile.familyMembers.count, 1)

        // Verify member
        XCTAssertTrue(member.isCurrentUser)
        XCTAssertEqual(member.role, .medicalAdmin)
        XCTAssertEqual(member.parentProfile?.name, "Mom")

        // Verify account
        XCTAssertNotNil(member.expenseAccount)
        XCTAssertEqual(member.expenseAccount?.balance, 0)
    }

    @MainActor
    func testOnboardingMinimalFieldsStillWorks() throws {
        // Only required fields: parent name and user name
        let profile = ParentProfile(name: "Dad")
        context.insert(profile)

        let member = FamilyMember(name: "Bob", role: .other, isCurrentUser: true)
        member.parentProfile = profile
        context.insert(member)

        let account = ExpenseAccount()
        account.familyMember = member
        member.expenseAccount = account
        context.insert(account)

        try context.save()

        XCTAssertEqual(profile.name, "Dad")
        XCTAssertNil(profile.bloodType)
        XCTAssertNil(profile.allergies)
        XCTAssertEqual(profile.familyMembers.count, 1)
        XCTAssertNotNil(member.expenseAccount)
    }
}
