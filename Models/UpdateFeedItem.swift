//
//  UpdateFeedItem.swift
//  CareCircle
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
    var id: UUID = UUID()
    var type: UpdateType = UpdateType.note
    var message: String = ""
    var authorName: String = ""
    var timestamp: Date = Date()

    var parentProfile: ParentProfile?

    init(
        id: UUID = UUID(),
        type: UpdateType = .note,
        message: String = "",
        authorName: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.authorName = authorName
        self.timestamp = timestamp
    }
}
