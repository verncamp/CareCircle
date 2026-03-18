//
//  ExpenseAccountTests.swift
//  CareCircleTests
//

import XCTest
import SwiftData
@testable import CareCircle

final class ExpenseAccountTests: XCTestCase {

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

    // MARK: - ExpenseAccount

    func testContributeIncreasesBalanceAndTotal() {
        let account = ExpenseAccount()
        XCTAssertEqual(account.balance, 0)
        XCTAssertEqual(account.totalContributed, 0)

        account.contribute(amount: 100)

        XCTAssertEqual(account.balance, 100)
        XCTAssertEqual(account.totalContributed, 100)
        XCTAssertEqual(account.totalSpent, 0)
    }

    func testSpendDecreasesBalanceAndIncreasesSpent() {
        let account = ExpenseAccount(balance: 200, totalContributed: 200)

        account.spend(amount: 75)

        XCTAssertEqual(account.balance, 125)
        XCTAssertEqual(account.totalSpent, 75)
        XCTAssertEqual(account.totalContributed, 200)
    }

    func testMultipleContributionsAccumulate() {
        let account = ExpenseAccount()

        account.contribute(amount: 50)
        account.contribute(amount: 30)
        account.contribute(amount: 20)

        XCTAssertEqual(account.balance, 100)
        XCTAssertEqual(account.totalContributed, 100)
    }

    func testSpendBelowZeroAllowed() {
        let account = ExpenseAccount()
        account.spend(amount: 50)

        XCTAssertEqual(account.balance, -50)
        XCTAssertEqual(account.totalSpent, 50)
    }

    func testContributeAndSpendSequence() {
        let account = ExpenseAccount()

        account.contribute(amount: 500)
        account.spend(amount: 120)
        account.spend(amount: 80)
        account.contribute(amount: 200)

        XCTAssertEqual(account.balance, 500)  // 500 - 120 - 80 + 200
        XCTAssertEqual(account.totalContributed, 700)
        XCTAssertEqual(account.totalSpent, 200)
    }

    func testUpdatedAtChangesOnContribute() {
        let account = ExpenseAccount()
        let before = account.updatedAt

        // Small delay to ensure timestamp differs
        Thread.sleep(forTimeInterval: 0.01)
        account.contribute(amount: 10)

        XCTAssertGreaterThanOrEqual(account.updatedAt, before)
    }

    func testUpdatedAtChangesOnSpend() {
        let account = ExpenseAccount()
        let before = account.updatedAt

        Thread.sleep(forTimeInterval: 0.01)
        account.spend(amount: 10)

        XCTAssertGreaterThanOrEqual(account.updatedAt, before)
    }
}
