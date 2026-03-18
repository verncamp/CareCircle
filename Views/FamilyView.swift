//
//  FamilyView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct FamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]
    @Query private var tasks: [Task]
    @State private var showingAddMember = false

    private let avatarGradients: [[Color]] = [
        [.teal, .mint],
        [.pink, .orange],
        [.purple, .pink],
        [.green, .teal],
        [.orange, .yellow]
    ]

    var openTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(familyMembers.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Members")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(openTasks.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(openTasks.isEmpty ? .green : .orange)
                            Text("Open Tasks")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .glassCard()

                    // Members
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Family Circle")

                        if familyMembers.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.3")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.teal.opacity(0.5))
                                Text("No family members yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(familyMembers) { member in
                                memberCard(member)
                            }
                        }
                    }

                    // Open Tasks
                    if !openTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Open Tasks")

                            ForEach(openTasks.prefix(5)) { task in
                                taskRow(task)
                            }
                        }
                        .glassCard()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .adaptiveWidth()
            }
            .navigationTitle("Family")
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView()
            }
        }
    }

    // MARK: - Member Card

    private func memberCard(_ member: FamilyMember) -> some View {
        let index = abs(member.name.hashValue) % avatarGradients.count

        return HStack(spacing: 14) {
            AvatarView(name: member.name, size: 48, gradient: avatarGradients[index])

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.body)
                        .fontWeight(.semibold)

                    if member.isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.teal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.teal.opacity(0.1), in: Capsule())
                    }
                }

                Text(member.role.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let openCount = member.assignedTasks.filter { !$0.isCompleted }.count
            if openCount > 0 {
                Text("\(openCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(.orange, in: Circle())
            }
        }
        .glassCard(padding: 14)
    }

    // MARK: - Task Row

    private func taskRow(_ task: Task) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.priority.icon)
                .foregroundStyle(task.priority.color)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)

                if let assigned = task.assignedTo {
                    Text("Assigned to \(assigned.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Unassigned")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Add Family Member Sheet

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
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMember() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
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
        .modelContainer(for: [
            FamilyMember.self, Task.self,
            ParentProfile.self, ExpenseAccount.self,
            Appointment.self, Document.self,
            Expense.self, UpdateFeedItem.self
        ], inMemory: true)
}
