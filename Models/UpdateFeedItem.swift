//
//  UpdateFeedItem.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import Foundation
import SwiftData

enum UpdateType: String, Codable {
    case note
    case taskCompleted
    case documentAdded
    case appointmentAdded
    case expenseAdded
}

@Model
final class UpdateFeedItem {
    var id: UUID
    var type: UpdateType
    var message: String
    var authorName: String
    var timestamp: Date
    
    // Relationship
    var parentProfile: ParentProfile?
    
    init(
        id: UUID = UUID(),
        type: UpdateType,
        message: String,
        authorName: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.authorName = authorName
        self.timestamp = timestamp
    }
}
