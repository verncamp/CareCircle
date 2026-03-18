//
//  ParentProfile.swift
//  CareCircle
//

import Foundation
import SwiftData

struct Medication: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var prescribedBy: String?
}

@Model
final class ParentProfile {
    var id: UUID = UUID()
    var name: String = ""
    var statusMessage: String = "Stable today"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Profile details
    @Attribute(.externalStorage) var photoData: Data?
    var dateOfBirth: Date?
    var bloodType: String?
    var allergies: String?
    var primaryPhysician: String?
    var insuranceProvider: String?
    var insuranceNumber: String?

    // Medical
    var medications: [Medication] = []
    var conditions: [String] = []

    // Emergency & pharmacy
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var pharmacyName: String?
    var pharmacyPhone: String?

    // Health
    var healthKitEnabled: Bool = false

    // Relationships
    @Relationship(deleteRule: .cascade) var appointments: [Appointment] = []
    @Relationship(deleteRule: .cascade) var tasks: [Task] = []
    @Relationship(deleteRule: .cascade) var documents: [Document] = []
    @Relationship(deleteRule: .cascade) var familyMembers: [FamilyMember] = []
    @Relationship(deleteRule: .cascade) var expenses: [Expense] = []
    @Relationship(deleteRule: .cascade) var updateFeedItems: [UpdateFeedItem] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        statusMessage: String = "Stable today",
        photoData: Data? = nil,
        dateOfBirth: Date? = nil,
        bloodType: String? = nil,
        allergies: String? = nil,
        primaryPhysician: String? = nil,
        insuranceProvider: String? = nil,
        insuranceNumber: String? = nil,
        medications: [Medication] = [],
        conditions: [String] = [],
        emergencyContactName: String? = nil,
        emergencyContactPhone: String? = nil,
        pharmacyName: String? = nil,
        pharmacyPhone: String? = nil,
        healthKitEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.statusMessage = statusMessage
        self.photoData = photoData
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.allergies = allergies
        self.primaryPhysician = primaryPhysician
        self.insuranceProvider = insuranceProvider
        self.insuranceNumber = insuranceNumber
        self.medications = medications
        self.conditions = conditions
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.pharmacyName = pharmacyName
        self.pharmacyPhone = pharmacyPhone
        self.healthKitEnabled = healthKitEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
