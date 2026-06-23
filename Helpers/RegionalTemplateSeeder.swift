//
//  RegionalTemplateSeeder.swift
//  CareCircle
//
//  Seeds region-specific critical document placeholders during onboarding.
//

import Foundation
import SwiftData

enum RegionalTemplateSeeder {
    static func seedDefaults(
        for profile: ParentProfile,
        region: RegionProfile,
        modelContext: ModelContext
    ) {
        guard profile.documents.isEmpty else { return }

        for template in templates(for: region) {
            let document = Document(
                title: template.title,
                category: template.category,
                domain: template.domain,
                countryProfileCode: region.countryCode,
                fileURL: "template://\(UUID().uuidString)",
                isPinned: template.isPinned,
                tags: ["template", region.countryCode],
                isCritical: true,
                includeInEmergencyPacket: template.includeInEmergencyPacket
            )
            document.parentProfile = profile
            modelContext.insert(document)
        }
    }

    private static func templates(for region: RegionProfile) -> [Template] {
        switch region {
        case .us:
            return [
                Template(title: "Medicare Card", category: .insurance, domain: .healthCoverage, isPinned: true, includeInEmergencyPacket: true),
                Template(title: "Medicaid Details", category: .insurance, domain: .healthCoverage, isPinned: false, includeInEmergencyPacket: true),
                Template(title: "Primary Insurance Card", category: .insurance, domain: .insurance, isPinned: true, includeInEmergencyPacket: true),
                Template(title: "IRS Tax Documents", category: .legal, domain: .tax, isPinned: false, includeInEmergencyPacket: false),
                Template(title: "Bank Account Authorization", category: .legal, domain: .banking, isPinned: false, includeInEmergencyPacket: false)
            ]
        case .ca:
            return [
                Template(title: "Provincial Health Card", category: .insurance, domain: .healthCoverage, isPinned: true, includeInEmergencyPacket: true),
                Template(title: "Private Insurance Card", category: .insurance, domain: .insurance, isPinned: true, includeInEmergencyPacket: true),
                Template(title: "CRA Tax Documents", category: .legal, domain: .tax, isPinned: false, includeInEmergencyPacket: false),
                Template(title: "Bank Account Authorization", category: .legal, domain: .banking, isPinned: false, includeInEmergencyPacket: false),
                Template(title: "Government ID", category: .legal, domain: .governmentId, isPinned: false, includeInEmergencyPacket: true)
            ]
        }
    }
}

private struct Template {
    let title: String
    let category: DocumentCategory
    let domain: DocumentDomain
    let isPinned: Bool
    let includeInEmergencyPacket: Bool
}
