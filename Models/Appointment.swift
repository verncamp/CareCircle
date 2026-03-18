//
//  Appointment.swift
//  CareCircle
//

import Foundation
import SwiftData

@Model
final class Appointment {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var location: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var checklistItems: [ChecklistItem] = []
    var aiSummary: String?
    var voiceNoteURL: String?
    var photoNoteURLs: [String] = []

    var parentProfile: ParentProfile?

    init(
        id: UUID = UUID(),
        title: String = "",
        date: Date = Date(),
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
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct ChecklistItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
}
