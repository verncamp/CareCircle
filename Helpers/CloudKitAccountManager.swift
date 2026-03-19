//
//  CloudKitAccountManager.swift
//  CareCircle
//
//  Checks iCloud account status. User identity (name/email) is entered
//  manually during onboarding rather than using deprecated CloudKit
//  discoverability APIs.
//

import CloudKit

@MainActor
@Observable
final class CloudKitAccountManager {
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var userName: String?
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

    init() {}

    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            self.accountStatus = status
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
