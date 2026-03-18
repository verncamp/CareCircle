//
//  FamilyMember.swift
//  CareCircle
//

import Foundation
import SwiftData

enum FamilyRole: String, Codable, CaseIterable {
    case medicalAdmin = "Medical Admin"
    case transportation = "Transportation"
    case bills = "Bills & Insurance"
    case dailyCheckIns = "Daily Check-ins"
    case other = "Other"
}

@Model
final class FamilyMember {
    var id: UUID = UUID()
    var name: String = ""
    var role: FamilyRole = FamilyRole.other
    var email: String?
    var phoneNumber: String?
    var isCurrentUser: Bool = false
    var createdAt: Date = Date()
    var airwallexUserID: String?

    var parentProfile: ParentProfile?
    var expenseAccount: ExpenseAccount?
    @Relationship(deleteRule: .nullify, inverse: \Task.assignedTo) var assignedTasks: [Task] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        role: FamilyRole = .other,
        email: String? = nil,
        phoneNumber: String? = nil,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
        self.phoneNumber = phoneNumber
        self.isCurrentUser = isCurrentUser
        self.createdAt = Date()
    }
}
