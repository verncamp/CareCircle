//
//  CloudKitAccountManager.swift
//  CareCircle
//
//  Uses iCloud account as user identity when available.
//  Fully degrades when CloudKit isn't provisioned or no iCloud account.
//

import Foundation
import CloudKit

@MainActor
@Observable
final class CloudKitAccountManager {
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var userName: String?
    private(set) var userEmail: String?
    private(set) var errorMessage: String?
    private(set) var isAvailable = false

    var isSignedIn: Bool { accountStatus == .available }

    var statusDescription: String {
        if !isAvailable { return "Offline mode" }
        switch accountStatus {
        case .available:              return "Connected"
        case .noAccount:              return "Not signed in to iCloud"
        case .restricted:             return "iCloud is restricted"
        case .couldNotDetermine:      return "Checking..."
        case .temporarilyUnavailable: return "Temporarily unavailable"
        @unknown default:             return "Unknown"
        }
    }

    nonisolated init() {}

    func checkAccountStatus() async {
        // First, check if we can even reach CloudKit without crashing.
        // FileManager.default.ubiquityIdentityToken is nil if no iCloud
        // account is configured — and it never traps.
        guard FileManager.default.ubiquityIdentityToken != nil else {
            isAvailable = false
            accountStatus = .noAccount
            return
        }

        do {
            let container = CKContainer(identifier: "iCloud.com.vernoncampbell.carecircle")
            let status = try await container.accountStatus()
            self.accountStatus = status
            self.isAvailable = true

            if status == .available {
                await fetchUserIdentity(container: container)
            }
        } catch {
            self.isAvailable = false
            self.accountStatus = .couldNotDetermine
            self.errorMessage = error.localizedDescription
        }
    }

    private func fetchUserIdentity(container: CKContainer) async {
        do {
            let recordID = try await container.userRecordID()
            let identity = try await container.userIdentity(forUserRecordID: recordID)

            if let components = identity?.nameComponents {
                let parts = [components.givenName, components.familyName].compactMap { $0 }
                if !parts.isEmpty {
                    self.userName = parts.joined(separator: " ")
                }
            }
        } catch {
            print("CloudKit identity unavailable: \(error.localizedDescription)")
        }
    }

    func requestDiscoverability() async {
        guard isAvailable else { return }
        do {
            let container = CKContainer(identifier: "iCloud.com.vernoncampbell.carecircle")
            let status = try await container.requestApplicationPermission(.userDiscoverability)
            if status == .granted {
                await fetchUserIdentity(container: container)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
