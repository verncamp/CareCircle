//
//  Expense.swift
//  CareCircle
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
    var id: UUID = UUID()
    var title: String = ""
    var amount: Decimal = 0
    var category: ExpenseCategory = ExpenseCategory.other
    var date: Date = Date()
    var notes: String = ""
    var createdAt: Date = Date()
    var paidBy: FamilyMember?
    var parentProfile: ParentProfile?

    init(
        id: UUID = UUID(),
        title: String = "",
        amount: Decimal = 0,
        category: ExpenseCategory = .other,
        date: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }
}
