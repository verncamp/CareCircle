//
//  Expense.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import Foundation
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable {
    case medical = "Medical"
    case medication = "Medication"
    case utilities = "Utilities"
    case groceries = "Groceries"
    case homeAide = "Home Aide"
    case transportation = "Transportation"
    case equipment = "Equipment"
    case other = "Other"
}

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Decimal
    var category: ExpenseCategory
    var date: Date
    var notes: String
    var receiptPhotoURL: String?
    var createdAt: Date
    
    // Who paid
    var paidBy: FamilyMember?
    
    // Split info (for future expansion)
    var isSplit: Bool
    var splitAmong: [String] // Array of family member IDs as strings
    
    // Future: Airwallex transaction ID
    var airwallexTransactionID: String?
    
    // Relationship
    var parentProfile: ParentProfile?
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        category: ExpenseCategory,
        date: Date = Date(),
        notes: String = "",
        receiptPhotoURL: String? = nil,
        isSplit: Bool = false,
        splitAmong: [String] = []
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.receiptPhotoURL = receiptPhotoURL
        self.isSplit = isSplit
        self.splitAmong = splitAmong
        self.createdAt = Date()
    }
}
