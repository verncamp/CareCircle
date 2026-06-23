//
//  RegionProfile.swift
//  CareCircle
//
//  Region selection and defaults for US/Canada experiences.
//

import Foundation

enum RegionProfile: String, Codable, CaseIterable {
    case us = "US"
    case ca = "Canada"

    var countryCode: String {
        switch self {
        case .us: return "US"
        case .ca: return "CA"
        }
    }

    var healthCoverageLabel: String {
        switch self {
        case .us: return "Medicare / Medicaid"
        case .ca: return "Provincial Health Card (OHIP, RAMQ, MSP, etc.)"
        }
    }

    static func from(countryCode: String?) -> RegionProfile {
        guard let code = countryCode?.uppercased() else { return .us }
        return code == "CA" ? .ca : .us
    }
}

enum RegionProfileResolver {
    static func suggested() -> RegionProfile {
        if let localeCode = Locale.current.region?.identifier.uppercased() {
            if localeCode == "CA" { return .ca }
            if localeCode == "US" { return .us }
        }

        return .us
    }
}
