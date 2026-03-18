//
//  EmergencyPacketTests.swift
//  CareCircleTests
//

import XCTest
@testable import CareCircle

final class EmergencyPacketTests: XCTestCase {

    func testGenerateReturnsPDFData() {
        let profile = ParentProfile(
            name: "Jane Doe",
            bloodType: "A+",
            allergies: "Penicillin",
            primaryPhysician: "Dr. Smith",
            insuranceProvider: "Blue Cross",
            insuranceNumber: "BC-12345",
            medications: [
                Medication(name: "Lisinopril", dosage: "10mg", frequency: "Once daily"),
                Medication(name: "Metformin", dosage: "500mg", frequency: "Twice daily")
            ],
            conditions: ["Hypertension", "Type 2 Diabetes"],
            emergencyContactName: "John Doe",
            emergencyContactPhone: "555-1234",
            pharmacyName: "CVS Pharmacy",
            pharmacyPhone: "555-5678"
        )

        let data = EmergencyPacketGenerator.generate(for: profile)

        XCTAssertNotNil(data)
        // PDF files start with %PDF
        XCTAssertTrue(data.count > 100, "PDF should have substantial content")
        let header = String(data: data.prefix(5), encoding: .ascii)
        XCTAssertEqual(header, "%PDF-")
    }

    func testGenerateWithMinimalProfile() {
        let profile = ParentProfile(name: "Minimal Patient")

        let data = EmergencyPacketGenerator.generate(for: profile)

        XCTAssertNotNil(data)
        let header = String(data: data.prefix(5), encoding: .ascii)
        XCTAssertEqual(header, "%PDF-")
    }

    func testGenerateWithEmptyMedications() {
        let profile = ParentProfile(
            name: "No Meds",
            medications: [],
            conditions: []
        )

        let data = EmergencyPacketGenerator.generate(for: profile)

        XCTAssertNotNil(data)
        XCTAssertTrue(data.count > 0)
    }

    func testGenerateWithManyMedications() {
        let meds = (1...20).map { i in
            Medication(name: "Med \(i)", dosage: "\(i * 5)mg", frequency: "Daily")
        }
        let profile = ParentProfile(
            name: "Many Meds Patient",
            medications: meds,
            conditions: ["Condition A", "Condition B", "Condition C"]
        )

        let data = EmergencyPacketGenerator.generate(for: profile)

        XCTAssertNotNil(data)
        // Should be multi-page with 20 medications
        XCTAssertTrue(data.count > 1000, "PDF with many meds should be substantial")
    }
}
