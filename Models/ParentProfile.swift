//
//  ParentProfile.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import Foundation
import SwiftData

@Model
final class ParentProfile {
    var id: UUID
    var name: String
    var statusMessage: String
    var createdAt: Date
    var updatedAt: Date
    
    // Profile details
    var dateOfBirth: Date?
    var bloodType: String?
    var allergies: String?
    var primaryPhysician: String?
    var insuranceProvider: String?
    var insuranceNumber: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var appointments: [Appointment]
    @Relationship(deleteRule: .cascade) var tasks: [Task]
    @Relationship(deleteRule: .cascade) var documents: [Document]
    @Relationship(deleteRule: .cascade) var familyMembers: [FamilyMember]
    @Relationship(deleteRule: .cascade) var expenses: [Expense]
    @Relationship(deleteRule: .cascade) var updateFeedItems: [UpdateFeedItem]
    
    init(
        id: UUID = UUID(),
        name: String,
        statusMessage: String = "Stable today",
        dateOfBirth: Date? = nil,
        bloodType: String? = nil,
        allergies: String? = nil,
        primaryPhysician: String? = nil,
        insuranceProvider: String? = nil,
        insuranceNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.statusMessage = statusMessage
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.allergies = allergies
        self.primaryPhysician = primaryPhysician
        self.insuranceProvider = insuranceProvider
        self.insuranceNumber = insuranceNumber
        self.createdAt = Date()
        self.updatedAt = Date()
        self.appointments = []
        self.tasks = []
        self.documents = []
        self.familyMembers = []
        self.expenses = []
        self.updateFeedItems = []
    }
}
