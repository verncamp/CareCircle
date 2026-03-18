//
//  ExpenseAccount.swift
//  CareCircle
//

import Foundation
import SwiftData

@Model
final class ExpenseAccount {
    var id: UUID = UUID()
    var balance: Decimal = 0
    var totalContributed: Decimal = 0
    var totalSpent: Decimal = 0
    var updatedAt: Date = Date()
    var airwallexAccountID: String?
    var airwallexWalletID: String?
    var familyMember: FamilyMember?

    init(
        id: UUID = UUID(),
        balance: Decimal = 0,
        totalContributed: Decimal = 0,
        totalSpent: Decimal = 0
    ) {
        self.id = id
        self.balance = balance
        self.totalContributed = totalContributed
        self.totalSpent = totalSpent
        self.updatedAt = Date()
    }

    func contribute(amount: Decimal) {
        self.balance += amount
        self.totalContributed += amount
        self.updatedAt = Date()
    }

    func spend(amount: Decimal) {
        self.balance -= amount
        self.totalSpent += amount
        self.updatedAt = Date()
    }
}
