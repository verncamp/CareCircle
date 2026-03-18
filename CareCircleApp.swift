//
//  CareCircleApp.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI
import SwiftData

@main
struct CareCircleApp: App {
    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
        .modelContainer(for: [
            ParentProfile.self,
            Appointment.self,
            Task.self,
            Document.self,
            FamilyMember.self,
            Expense.self,
            ExpenseAccount.self,
            UpdateFeedItem.self
        ])
    }
}
