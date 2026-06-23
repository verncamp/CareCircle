//
//  RegionalDocumentTests.swift
//  CareCircleTests
//
//  Tests for region defaults, document metadata, and regional template seeding.
//

import XCTest
import SwiftData
@testable import CareCircle

final class RegionalDocumentTests: XCTestCase {

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

    func testRegionProfileMetadata() {
        XCTAssertEqual(RegionProfile.us.countryCode, "US")
        XCTAssertEqual(RegionProfile.ca.countryCode, "CA")
        XCTAssertTrue(RegionProfile.us.healthCoverageLabel.contains("Medicare"))
        XCTAssertTrue(RegionProfile.ca.healthCoverageLabel.contains("Provincial"))
    }

    func testParentProfileRegionDefaultsAndOverrides() {
        let defaultProfile = ParentProfile(name: "Default Region")
        XCTAssertEqual(defaultProfile.regionProfileCode, "US")

        let caProfile = ParentProfile(name: "CA Region", regionProfileCode: "CA")
        XCTAssertEqual(caProfile.regionProfileCode, "CA")
    }

    func testDocumentStoresExtendedMetadata() {
        let expiry = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let renewal = Calendar.current.date(byAdding: .day, value: 15, to: Date())!

        let document = Document(
            title: "Primary Insurance Card",
            category: .insurance,
            domain: .insurance,
            countryProfileCode: "CA",
            fileURL: "file://insurance-card.pdf",
            isPinned: true,
            tags: ["critical", "insurance"],
            issuer: "Blue Shield",
            memberOrPolicyId: "POL-123",
            expiryDate: expiry,
            renewalDate: renewal,
            isCritical: true,
            includeInEmergencyPacket: true
        )

        XCTAssertEqual(document.domain, .insurance)
        XCTAssertEqual(document.countryProfileCode, "CA")
        XCTAssertEqual(document.issuer, "Blue Shield")
        XCTAssertEqual(document.memberOrPolicyId, "POL-123")
        XCTAssertEqual(document.expiryDate, expiry)
        XCTAssertEqual(document.renewalDate, renewal)
        XCTAssertTrue(document.isCritical)
        XCTAssertTrue(document.includeInEmergencyPacket)
    }

    func testDocumentCountryProfileComputedProperty() {
        let document = Document(title: "Doc", countryProfileCode: "CA")
        XCTAssertEqual(document.countryProfile, .ca)
        document.countryProfile = .us
        XCTAssertEqual(document.countryProfileCode, "US")
    }

    func testNotificationPreferencesPersistRoundTrip() {
        var preferences = CareNotificationPreferences.load()
        preferences.appointment24h = false
        preferences.appointment2h = true
        preferences.appointment30m = true
        preferences.taskDueEnabled = false
        preferences.document7d = false
        preferences.emergencyPacketCadenceDays = 90
        preferences.weeklyReadinessDigest = true
        preferences.save()

        let restored = CareNotificationPreferences.load()
        XCTAssertFalse(restored.appointment24h)
        XCTAssertTrue(restored.appointment2h)
        XCTAssertTrue(restored.appointment30m)
        XCTAssertFalse(restored.taskDueEnabled)
        XCTAssertFalse(restored.document7d)
        XCTAssertEqual(restored.emergencyPacketCadenceDays, 90)
        XCTAssertTrue(restored.weeklyReadinessDigest)
    }

    @MainActor
    func testRegionalSeederSeedsUSDefaults() throws {
        let profile = ParentProfile(name: "US Profile")
        context.insert(profile)

        RegionalTemplateSeeder.seedDefaults(
            for: profile,
            region: .us,
            modelContext: context
        )
        try context.save()

        let seeded = try context.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(seeded.count, 5)
        XCTAssertTrue(seeded.allSatisfy { $0.isCritical })
        XCTAssertTrue(seeded.allSatisfy { $0.countryProfileCode == "US" })
        XCTAssertTrue(seeded.allSatisfy { $0.tags.contains("template") })
        XCTAssertTrue(seeded.contains { $0.title == "Medicare Card" && $0.domain == .healthCoverage })
        XCTAssertTrue(seeded.contains { $0.title == "IRS Tax Documents" && $0.domain == .tax })
    }

    @MainActor
    func testRegionalSeederSeedsCanadaDefaults() throws {
        let profile = ParentProfile(name: "CA Profile")
        context.insert(profile)

        RegionalTemplateSeeder.seedDefaults(
            for: profile,
            region: .ca,
            modelContext: context
        )
        try context.save()

        let seeded = try context.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(seeded.count, 5)
        XCTAssertTrue(seeded.allSatisfy { $0.countryProfileCode == "CA" })
        XCTAssertTrue(seeded.contains { $0.title == "Provincial Health Card" && $0.includeInEmergencyPacket })
        XCTAssertTrue(seeded.contains { $0.title == "CRA Tax Documents" && $0.domain == .tax })
        XCTAssertTrue(seeded.contains { $0.title == "Government ID" && $0.domain == .governmentId })
    }

    @MainActor
    func testRegionalSeederDoesNotDuplicateExistingDocuments() throws {
        let profile = ParentProfile(name: "Existing Docs")
        context.insert(profile)

        let existing = Document(
            title: "Existing Document",
            category: .legal,
            domain: .legal,
            countryProfileCode: "US",
            fileURL: "file://existing.pdf"
        )
        existing.parentProfile = profile
        context.insert(existing)
        try context.save()

        RegionalTemplateSeeder.seedDefaults(
            for: profile,
            region: .us,
            modelContext: context
        )
        try context.save()

        let docs = try context.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs.first?.title, "Existing Document")
    }
}
