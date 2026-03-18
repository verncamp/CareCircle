//
//  Document.swift
//  CareCircle
//
//  Created on March 17, 2026.
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
    var id: UUID
    var title: String
    var category: DocumentCategory
    var fileURL: String // Local file path or future cloud URL
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // AI-generated tags or metadata (optional)
    var tags: [String]
    var aiExtractedText: String?
    
    // Relationship
    var parentProfile: ParentProfile?
    
    init(
        id: UUID = UUID(),
        title: String,
        category: DocumentCategory = .other,
        fileURL: String,
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
