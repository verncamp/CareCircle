//
//  SampleDataGenerator.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import Foundation
import SwiftData

@MainActor
struct SampleDataGenerator {
    
    static func generateSampleData(modelContext: ModelContext) {
        // Create parent profile
        let parent = ParentProfile(
            name: "Mom Alvarez",
            statusMessage: "Stable today",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -78, to: Date()),
            bloodType: "O+",
            allergies: "Penicillin",
            primaryPhysician: "Dr. Sarah Chen",
            insuranceProvider: "Blue Cross Blue Shield",
            insuranceNumber: "MC123456789",
            medications: [
                Medication(name: "Lisinopril", dosage: "10mg", frequency: "Once daily", prescribedBy: "Dr. Chen"),
                Medication(name: "Metformin", dosage: "500mg", frequency: "Twice daily", prescribedBy: "Dr. Chen"),
                Medication(name: "Aspirin", dosage: "81mg", frequency: "Once daily")
            ],
            conditions: ["Hypertension", "Type 2 Diabetes", "Osteoarthritis"],
            emergencyContactName: "Maria (Aide)",
            emergencyContactPhone: "555-0125",
            pharmacyName: "CVS Pharmacy - Main St",
            pharmacyPhone: "555-0200"
        )
        modelContext.insert(parent)
        
        // Create family members
        let familyMembers = [
            FamilyMember(name: "You", role: .medicalAdmin, email: "you@example.com", isCurrentUser: true),
            FamilyMember(name: "Sarah", role: .transportation, email: "sarah@example.com", phoneNumber: "555-0123"),
            FamilyMember(name: "Daniel", role: .bills, email: "daniel@example.com", phoneNumber: "555-0124"),
            FamilyMember(name: "Maria (Aide)", role: .dailyCheckIns, phoneNumber: "555-0125")
        ]
        
        for member in familyMembers {
            member.parentProfile = parent
            modelContext.insert(member)
            
            // Create expense accounts for each member
            let contributed = Decimal(Int.random(in: 500...2000))
            let spent = Decimal(Int.random(in: 100...Int(truncating: contributed as NSDecimalNumber)))
            let account = ExpenseAccount(
                balance: contributed - spent,
                totalContributed: contributed,
                totalSpent: spent
            )
            account.familyMember = member
            member.expenseAccount = account
            modelContext.insert(account)
        }
        
        // Create appointments
        let appointments = [
            Appointment(
                title: "Cardiology Follow-up",
                date: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
                location: "St. Mary's Hospital - Cardiology Wing",
                notes: "Discuss recent blood pressure readings and medication adjustment",
                checklistItems: [
                    ChecklistItem(title: "Insurance card", isCompleted: true),
                    ChecklistItem(title: "Medication list", isCompleted: true),
                    ChecklistItem(title: "Last lab report", isCompleted: false),
                    ChecklistItem(title: "Blood pressure log", isCompleted: true)
                ]
            ),
            Appointment(
                title: "Physical Therapy",
                date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                location: "Valley PT Center",
                notes: "Knee exercises and mobility assessment",
                checklistItems: [
                    ChecklistItem(title: "Comfortable clothing", isCompleted: false),
                    ChecklistItem(title: "Water bottle", isCompleted: false)
                ]
            ),
            Appointment(
                title: "Primary Care Annual",
                date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date(),
                location: "Family Medical Associates",
                notes: "Annual checkup and medication review",
                checklistItems: [
                    ChecklistItem(title: "List of questions", isCompleted: false),
                    ChecklistItem(title: "Current medications", isCompleted: false)
                ]
            )
        ]
        
        for appointment in appointments {
            appointment.parentProfile = parent
            modelContext.insert(appointment)
        }
        
        // Create tasks
        let tasks = [
            Task(title: "Refill blood pressure medication", taskDescription: "Call pharmacy for refill", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), priority: .urgent),
            Task(title: "Upload discharge summary to Vault", taskDescription: "Scan and organize hospital discharge papers", priority: .high),
            Task(title: "Confirm PT appointment ride", taskDescription: "Check with Sarah about Thursday transportation", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), priority: .high),
            Task(title: "Review insurance EOB", taskDescription: "Check explanation of benefits for recent ER visit", priority: .normal),
            Task(title: "Order shower chair", taskDescription: "Medical supply store or Amazon", priority: .normal),
            Task(title: "Schedule eye exam", taskDescription: "Annual vision checkup due", priority: .low)
        ]
        
        for (index, task) in tasks.enumerated() {
            task.parentProfile = parent
            if index < familyMembers.count {
                task.assignedTo = familyMembers[index]
            }
            modelContext.insert(task)
        }
        
        // Create documents
        let documents = [
            Document(title: "Insurance Card", category: .insurance, fileURL: "sample://insurance-card.pdf", isPinned: true, tags: ["Blue Cross", "Primary"]),
            Document(title: "Medication List (Current)", category: .medication, fileURL: "sample://med-list.pdf", isPinned: true, tags: ["Updated", "Current"]),
            Document(title: "Power of Attorney", category: .legal, fileURL: "sample://poa.pdf", isPinned: true, tags: ["Legal", "Important"]),
            Document(title: "Lab Results - March 2026", category: .lab, fileURL: "sample://lab-mar-2026.pdf", tags: ["Recent", "Cardiology"]),
            Document(title: "Hospital Discharge Summary", category: .medical, fileURL: "sample://discharge.pdf", tags: ["ER", "February"]),
            Document(title: "COVID-19 Vaccination Record", category: .vaccination, fileURL: "sample://covid-vax.pdf", tags: ["Vaccination", "2025"]),
            Document(title: "Medicare Card", category: .insurance, fileURL: "sample://medicare.pdf", tags: ["Medicare"]),
            Document(title: "Living Will", category: .legal, fileURL: "sample://living-will.pdf", tags: ["Legal", "Advance Directives"])
        ]
        
        for document in documents {
            document.parentProfile = parent
            modelContext.insert(document)
        }
        
        // Create expenses
        let expenses = [
            Expense(title: "Blood pressure medication", amount: 45.50, category: .medication, date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), notes: "Monthly refill"),
            Expense(title: "Home health aide (weekly)", amount: 320.00, category: .homeAide, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            Expense(title: "Grocery delivery", amount: 87.35, category: .groceries, date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
            Expense(title: "Electric bill", amount: 142.00, category: .utilities, date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()),
            Expense(title: "Rideshare to cardiology", amount: 28.50, category: .transportation, date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()),
            Expense(title: "Walker with wheels", amount: 89.99, category: .equipment, date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()),
            Expense(title: "Copay - Primary care", amount: 25.00, category: .medical, date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date())
        ]
        
        for (index, expense) in expenses.enumerated() {
            expense.parentProfile = parent
            expense.paidBy = familyMembers[index % familyMembers.count]
            modelContext.insert(expense)
        }
        
        // Create update feed items
        let updates = [
            UpdateFeedItem(type: .note, message: "Vitals looked good at today's checkup", authorName: "Sarah", timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()),
            UpdateFeedItem(type: .documentAdded, message: "Uploaded discharge summary to Vault", authorName: "You", timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()),
            UpdateFeedItem(type: .taskCompleted, message: "Picked up prescriptions", authorName: "Daniel", timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()),
            UpdateFeedItem(type: .expenseAdded, message: "Paid electric bill ($142)", authorName: "You", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            UpdateFeedItem(type: .appointmentAdded, message: "Scheduled PT for Thursday", authorName: "Sarah", timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date())
        ]
        
        for update in updates {
            update.parentProfile = parent
            modelContext.insert(update)
        }
        
        // Save all
        try? modelContext.save()
    }
    
    static func clearAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: ParentProfile.self)
            try modelContext.delete(model: Appointment.self)
            try modelContext.delete(model: Task.self)
            try modelContext.delete(model: Document.self)
            try modelContext.delete(model: FamilyMember.self)
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: ExpenseAccount.self)
            try modelContext.delete(model: UpdateFeedItem.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}
