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

        switch mode {
        case "demo":
            // In-memory, no persistence, no CloudKit
            config = ModelConfiguration(
                "CareCircleDemo",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        case "real":
            // Signed-up user: persistent store with CloudKit sync
            config = ModelConfiguration(
                "CareCircle",
                schema: schema,
                cloudKitDatabase: .automatic
            )
        default:
            // "none", "signup", or any other state: local-only persistent store
            // No CloudKit until the user completes onboarding
            config = ModelConfiguration(
                "CareCircle",
                schema: schema,
                cloudKitDatabase: .none
            )
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema migration failed — delete old store and retry
            print("ModelContainer init failed, resetting store: \(error)")
            Self.deleteExistingStore()
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
        .modelContainer(modelContainer)
    }

    private static func deleteExistingStore() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }

        let suffixes = ["store", "store-shm", "store-wal"]
        let names = ["CareCircle", "default"]

        for name in names {
            for suffix in suffixes {
                let url = appSupport.appendingPathComponent("\(name).\(suffix)")
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
