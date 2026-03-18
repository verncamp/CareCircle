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

        if mode == "demo" {
            // Demo: in-memory, no CloudKit sync
            let config = ModelConfiguration(
                "CareCircleDemo",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create demo ModelContainer: \(error)")
            }
        } else {
            // Real: CloudKit-backed persistent store
            let config = ModelConfiguration(
                "CareCircle",
                schema: schema,
                cloudKitDatabase: .automatic
            )
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                // Migration failed — delete the old store and retry
                print("ModelContainer failed, clearing store: \(error)")
                Self.deleteExistingStore(named: "CareCircle")
                do {
                    modelContainer = try ModelContainer(for: schema, configurations: [config])
                } catch {
                    fatalError("Failed to create ModelContainer after reset: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
        .modelContainer(modelContainer)
    }

    /// Remove an incompatible SwiftData store so a fresh one can be created.
    private static func deleteExistingStore(named name: String) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let extensions = ["store", "store-shm", "store-wal"]
        for ext in extensions {
            let url = appSupport.appendingPathComponent("\(name).\(ext)")
            try? FileManager.default.removeItem(at: url)
        }
        // Also try default.store
        for ext in extensions {
            let url = appSupport.appendingPathComponent("default.\(ext)")
            try? FileManager.default.removeItem(at: url)
        }
    }
}
