//
//  Document.swift
//  CareCircle
//

import Foundation
import SwiftData

enum DocumentCategory: String, Codable, CaseIterable {
    case insurance = "Insurance"
    case medical = "Medical Records"
    case legal = "Legal Documents"
    case medication = "Medications"
    case lab = "Lab Results"
    case vaccination = "Vaccinations"
    case other = "Other"
}

enum DocumentDomain: String, Codable, CaseIterable {
    case tax = "Tax"
    case insurance = "Insurance"
    case banking = "Banking"
    case healthCoverage = "Health Coverage"
    case governmentId = "Government ID"
    case legal = "Legal"
    case other = "Other"
}

enum DocumentCountryProfile: String, Codable, CaseIterable {
    case us = "US"
    case ca = "CA"
}

@Model
final class Document {
    var id: UUID = UUID()
    var title: String = ""
    var category: DocumentCategory
    var fileURL: String = ""
    @Attribute(.externalStorage) var fileData: Data?
    var isPinned: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var tags: [String] = []
    var aiExtractedText: String?
    var domain: DocumentDomain
    var countryProfileCode: String = "US"
    var issuer: String?
    var memberOrPolicyId: String?
    var expiryDate: Date?
    var renewalDate: Date?
    var isCritical: Bool = false
    var includeInEmergencyPacket: Bool = false

    var parentProfile: ParentProfile?

    var countryProfile: DocumentCountryProfile {
        get { DocumentCountryProfile(rawValue: countryProfileCode.uppercased()) ?? .us }
        set { countryProfileCode = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        category: DocumentCategory = .other,
        domain: DocumentDomain = .other,
        countryProfileCode: String = "US",
        fileURL: String = "",
        isPinned: Bool = false,
        tags: [String] = [],
        issuer: String? = nil,
        memberOrPolicyId: String? = nil,
        expiryDate: Date? = nil,
        renewalDate: Date? = nil,
        isCritical: Bool = false,
        includeInEmergencyPacket: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.domain = domain
        self.countryProfileCode = countryProfileCode
        self.fileURL = fileURL
        self.isPinned = isPinned
        self.tags = tags
        self.issuer = issuer
        self.memberOrPolicyId = memberOrPolicyId
        self.expiryDate = expiryDate
        self.renewalDate = renewalDate
        self.isCritical = isCritical
        self.includeInEmergencyPacket = includeInEmergencyPacket
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
