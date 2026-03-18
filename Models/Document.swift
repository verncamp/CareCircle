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

@Model
final class Document {
    var id: UUID = UUID()
    var title: String = ""
    var category: DocumentCategory = DocumentCategory.other
    var fileURL: String = ""
    @Attribute(.externalStorage) var fileData: Data?
    var isPinned: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var tags: [String] = []
    var aiExtractedText: String?

    var parentProfile: ParentProfile?

    init(
        id: UUID = UUID(),
        title: String = "",
        category: DocumentCategory = .other,
        fileURL: String = "",
        isPinned: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.fileURL = fileURL
        self.isPinned = isPinned
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
