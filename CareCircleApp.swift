//
//  CareCircleApp.swift
//  CareCircle
//

import SwiftUI
import SwiftData

@main
struct CareCircleApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            ParentProfile.self,
            Appointment.self,
            Task.self,
            Document.self,
            FamilyMember.self,
            Expense.self,
            ExpenseAccount.self,
            UpdateFeedItem.self
        ])

        let mode = UserDefaults.standard.string(forKey: "appMode") ?? "none"

        let config: ModelConfiguration
        if mode == "demo" {
            // Demo: in-memory, no CloudKit sync
            config = ModelConfiguration(
                "CareCircleDemo",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            // Real: CloudKit-backed persistent store
            config = ModelConfiguration(
                "CareCircle",
                schema: schema,
                cloudKitDatabase: .automatic
            )
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
        .modelContainer(modelContainer)
    }
}
