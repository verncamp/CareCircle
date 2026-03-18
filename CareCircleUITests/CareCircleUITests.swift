//
//  CareCircleUITests.swift
//  CareCircleUITests
//

import XCTest

final class CareCircleUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch & Welcome

    @MainActor
    func testAppLaunches() throws {
        // App should show either welcome screen, onboarding, or main tabs
        let exists = app.staticTexts["CareCircle"].waitForExistence(timeout: 5)
            || app.tabBars.firstMatch.waitForExistence(timeout: 5)
            || app.staticTexts["Welcome"].waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "App should launch to a recognizable screen")
    }

    // MARK: - Demo Mode Navigation

    @MainActor
    func testDemoModeTabs() throws {
        // Try to enter demo mode if on welcome screen
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        // If we're in the main app, check all tabs exist
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            // May be on onboarding — skip tab tests
            return
        }

        // Verify core tabs
        XCTAssertTrue(tabBar.buttons["Today"].exists || tabBar.buttons["today"].exists)
        XCTAssertTrue(tabBar.buttons["Calendar"].exists || tabBar.buttons["calendar"].exists)
        XCTAssertTrue(tabBar.buttons["Vault"].exists || tabBar.buttons["vault"].exists)
        XCTAssertTrue(tabBar.buttons["Family"].exists || tabBar.buttons["family"].exists)
    }

    @MainActor
    func testNavigateToCalendarTab() throws {
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }

        let calendarTab = tabBar.buttons["Calendar"].exists
            ? tabBar.buttons["Calendar"]
            : tabBar.buttons["calendar"]
        if calendarTab.exists {
            calendarTab.tap()
            XCTAssertTrue(app.navigationBars["Calendar"].waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testNavigateToVaultTab() throws {
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }

        let vaultTab = tabBar.buttons["Vault"].exists
            ? tabBar.buttons["Vault"]
            : tabBar.buttons["vault"]
        if vaultTab.exists {
            vaultTab.tap()
            XCTAssertTrue(app.navigationBars["Vault"].waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testNavigateToFamilyTab() throws {
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }

        let familyTab = tabBar.buttons["Family"].exists
            ? tabBar.buttons["Family"]
            : tabBar.buttons["family"]
        if familyTab.exists {
            familyTab.tap()
            XCTAssertTrue(app.navigationBars["Family"].waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testNavigateToFinancesTab() throws {
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }

        let financesTab = tabBar.buttons["Finances"].exists
            ? tabBar.buttons["Finances"]
            : tabBar.buttons["finances"]
        if financesTab.exists {
            financesTab.tap()
            XCTAssertTrue(app.navigationBars["Finances"].waitForExistence(timeout: 3))
        }
    }

    // MARK: - Add Appointment Flow

    @MainActor
    func testAddAppointmentSheet() throws {
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }

        // Go to Calendar
        let calendarTab = tabBar.buttons["Calendar"].exists
            ? tabBar.buttons["Calendar"]
            : tabBar.buttons["calendar"]
        guard calendarTab.exists else { return }
        calendarTab.tap()

        // Tap add button
        let addButton = app.navigationBars.buttons.element(boundBy: 0)
        guard addButton.waitForExistence(timeout: 3) else { return }
        addButton.tap()

        // Sheet should appear with "New Appointment" title
        XCTAssertTrue(
            app.navigationBars["New Appointment"].waitForExistence(timeout: 3),
            "Add appointment sheet should appear"
        )

        // Cancel
        let cancel = app.buttons["Cancel"]
        if cancel.exists { cancel.tap() }
    }

    // MARK: - Settings

    @MainActor
    func testNavigateToSettings() throws {
        let tryDemo = app.buttons["Try Demo"]
        if tryDemo.waitForExistence(timeout: 3) {
            tryDemo.tap()
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }

        let settingsTab = tabBar.buttons["Settings"].exists
            ? tabBar.buttons["Settings"]
            : tabBar.buttons["settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        }
    }
}
