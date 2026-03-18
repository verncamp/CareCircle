//
//  Task.swift
//  CareCircle
//

import Foundation
import SwiftData

enum TaskPriority: String, Codable {
    case low
    case normal
    case high
    case urgent
}

@Model
final class Task {
    var id: UUID = UUID()
    var title: String = ""
    var taskDescription: String = ""
    var dueDate: Date?
    var isCompleted: Bool = false
    var priority: TaskPriority = TaskPriority.normal
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var assignedTo: FamilyMember?
    var parentProfile: ParentProfile?

    init(
        id: UUID = UUID(),
        title: String = "",
        taskDescription: String = "",
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        priority: TaskPriority = .normal
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
