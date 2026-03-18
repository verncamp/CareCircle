//
//  CloudKitAccountManager.swift
//  CareCircle
//
//  Uses iCloud account as user identity. No separate auth needed.
//

import CloudKit

@MainActor
@Observable
final class CloudKitAccountManager {
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var userName: String?
    private(set) var userEmail: String?
    private(set) var errorMessage: String?

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
    
    nonisolated init() {}

    func checkAccountStatus() async {
        let status: CKAccountStatus
        do {
            status = try await CKContainer.default().accountStatus()
        } catch {
            self.errorMessage = error.localizedDescription
            return
        }
        
        self.accountStatus = status

        if status == .available {
            await fetchUserIdentity()
        }
    }

    private func fetchUserIdentity() async {
        let recordID: CKRecord.ID
        let identity: CKUserIdentity?
        
        do {
            recordID = try await CKContainer.default().userRecordID()
            identity = try await CKContainer.default().userIdentity(forUserRecordID: recordID)
        } catch {
            // Discoverability not granted — user can enter name manually
            print("Failed to fetch user identity: \(error.localizedDescription)")
            return
        }

        if let components = identity?.nameComponents {
            let parts = [components.givenName, components.familyName].compactMap { $0 }
            if !parts.isEmpty {
                self.userName = parts.joined(separator: " ")
            }
        }
    }

    func requestDiscoverability() async {
        let status: CKContainer_Application_PermissionStatus
        do {
            status = try await CKContainer.default().requestApplicationPermission(.userDiscoverability)
        } catch {
            self.errorMessage = error.localizedDescription
            return
        }
        
        if status == .granted {
            await fetchUserIdentity()
        }
    }
}
