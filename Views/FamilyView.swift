//
//  FamilyView.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI
import SwiftData

struct FamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]
    @Query private var tasks: [Task]
    @State private var showingAddMember = false
    
    var openTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(familyMembers.count) member\(familyMembers.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Family Circle")
                }
                
                Section("Members") {
                    if familyMembers.isEmpty {
                        Text("No family members yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(familyMembers) { member in
                            FamilyMemberRow(member: member)
                        }
                    }
                }
                
                Section("Open Tasks") {
                    if openTasks.isEmpty {
                        Text("No open tasks")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(openTasks.prefix(5)) { task in
                            TaskAssignmentRow(task: task)
                        }
                    }
                }
            }
            .navigationTitle("Family")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddMember = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView()
            }
        }
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(member.name.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if member.isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(member.role.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TaskAssignmentRow: View {
    let task: Task
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                
                if let assignedTo = task.assignedTo {
                    Text("Assigned to \(assignedTo.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Unassigned")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            if task.priority == .urgent || task.priority == .high {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(task.priority == .urgent ? .red : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    
    @State private var name = ""
    @State private var role: FamilyRole = .other
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var isCurrentUser = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Role", selection: $role) {
                        ForEach(FamilyRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    
                    Toggle("This is me", isOn: $isCurrentUser)
                }
                
                Section("Contact (Optional)") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Phone", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMember()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func saveMember() {
        let member = FamilyMember(
            name: name,
            role: role,
            email: email.isEmpty ? nil : email,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            isCurrentUser: isCurrentUser
        )
        
        member.parentProfile = parentProfiles.first
        
        // Create an expense account for the member
        let account = ExpenseAccount()
        account.familyMember = member
        member.expenseAccount = account
        
        modelContext.insert(member)
        modelContext.insert(account)
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    FamilyView()
        .modelContainer(for: [FamilyMember.self, Task.self, ParentProfile.self], inMemory: true)
}
