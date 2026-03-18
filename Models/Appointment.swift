//
//  Appointment.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import Foundation
import SwiftData

@Model
final class Appointment {
    var id: UUID
    var title: String
    var date: Date
    var location: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    // Checklist items (stored as JSON array of strings for simplicity)
    var checklistItems: [ChecklistItem]
    
    // AI summary (optional, generated after appointment)
    var aiSummary: String?
    
    // Voice/photo notes data (file references or base64 for MVP)
    var voiceNoteURL: String?
    var photoNoteURLs: [String]
    
    // Relationship
    var parentProfile: ParentProfile?
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        location: String = "",
        notes: String = "",
        checklistItems: [ChecklistItem] = [],
        aiSummary: String? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.notes = notes
        self.checklistItems = checklistItems
        self.aiSummary = aiSummary
        self.voiceNoteURL = nil
        self.photoNoteURLs = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Checklist item model (codable struct for simple storage)
struct ChecklistItem: Codable, Identifiable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}
