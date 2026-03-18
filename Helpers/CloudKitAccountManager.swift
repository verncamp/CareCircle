//
//  CloudKitAccountManager.swift
//  CareCircle
//
//  Uses iCloud account as user identity. No separate auth needed.
//

import CloudKit

@Observable
@MainActor
final class CloudKitAccountManager {
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var userName: String?
    var userEmail: String?
    var errorMessage: String?

    var isSignedIn: Bool { accountStatus == .available }

    var statusDescription: String {
        switch accountStatus {
        case .available:              return "Connected"
        case .noAccount:              return "Not signed in to iCloud"
        case .restricted:             return "iCloud is restricted"
        case .couldNotDetermine:      return "Checking..."
        case .temporarilyUnavailable: return "Temporarily unavailable"
        @unknown default:             return "Unknown"
        }
    }

    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            self.accountStatus = status

            if status == .available {
                await fetchUserIdentity()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchUserIdentity() async {
        do {
            let id = try await CKContainer.default().userRecordID()
            let identity = try await CKContainer.default().userIdentity(forUserRecordID: id)

            if let components = identity?.nameComponents {
                let parts = [components.givenName, components.familyName].compactMap { $0 }
                if !parts.isEmpty {
                    userName = parts.joined(separator: " ")
                }
            }
        } catch {
            // Discoverability not granted — user can enter name manually
        }
    }

    func requestDiscoverability() async {
        do {
            let status = try await CKContainer.default().requestApplicationPermission(.userDiscoverability)
            if status == .granted {
                await fetchUserIdentity()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
