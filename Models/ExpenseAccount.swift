//
//  ExpenseAccount.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import Foundation
import SwiftData

@Model
final class ExpenseAccount {
    var id: UUID
    var balance: Decimal
    var totalContributed: Decimal
    var totalSpent: Decimal
    var updatedAt: Date
    
    // Future: Airwallex account/wallet ID
    var airwallexAccountID: String?
    var airwallexWalletID: String?
    
    // Relationship - one account per family member
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
