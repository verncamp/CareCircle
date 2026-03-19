//
//  FamilyMemberDetailView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct FamilyMemberDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var member: FamilyMember

    @State private var showingEdit = false

    private let avatarGradients: [[Color]] = [
        [.teal, .mint],
        [.pink, .orange],
        [.purple, .pink],
        [.green, .teal],
        [.orange, .yellow]
    ]

    private var gradient: [Color] {
        avatarGradients[abs(member.name.hashValue) % avatarGradients.count]
    }

    var openTasks: [Task] {
        member.assignedTasks.filter { !$0.isCompleted }
    }

    var completedTasks: [Task] {
        member.assignedTasks.filter { $0.isCompleted }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard
                contactCard

                if let account = member.expenseAccount {
                    accountCard(account)
                }

                tasksCard
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .adaptiveWidth()
        }
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditFamilyMemberView(member: member)
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        VStack(spacing: 14) {
            AvatarView(name: member.name, size: 72, gradient: gradient)

            Text(member.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                Text(member.role.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

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
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Contact

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Contact")

            if let email = member.email, !email.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.teal)
                        .frame(width: 20)
                    Text(email)
                        .font(.subheadline)
                    Spacer()
                }
            }

            if let phone = member.phoneNumber, !phone.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.teal)
                        .frame(width: 20)
                    Text(phone)
                        .font(.subheadline)
                    Spacer()
                }
            }

            if (member.email == nil || member.email?.isEmpty == true) &&
               (member.phoneNumber == nil || member.phoneNumber?.isEmpty == true) {
                Text("No contact info added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }

    // MARK: - Account

    private func accountCard(_ account: ExpenseAccount) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Account")

            HStack {
                Text("Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(account.balance))
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            HStack {
                Text("Contributed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(account.totalContributed))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }

            HStack {
                Text("Spent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(account.totalSpent))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
            }
        }
        .glassCard()
    }

    // MARK: - Tasks

    private var tasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Assigned Tasks")
                Spacer()
                Text("\(openTasks.count) open")
                    .font(.caption)
                    .foregroundStyle(openTasks.isEmpty ? .green : .orange)
                    .fontWeight(.medium)
            }

            if member.assignedTasks.isEmpty {
                Text("No tasks assigned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(openTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        taskRow(task)
                    }
                    .buttonStyle(.plain)
                }

                if !completedTasks.isEmpty {
                    Text("\(completedTasks.count) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .glassCard()
    }

    private func taskRow(_ task: Task) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(task.priority.color.opacity(0.6))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)

                if let due = task.dueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: task.priority.icon)
                .foregroundStyle(task.priority.color)
                .font(.caption)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Edit Family Member

struct EditFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var member: FamilyMember

    @State private var name = ""
    @State private var role: FamilyRole = .other
    @State private var email = ""
    @State private var phoneNumber = ""

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
                }

                Section("Contact") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField("Phone", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = member.name
                role = member.role
                email = member.email ?? ""
                phoneNumber = member.phoneNumber ?? ""
            }
        }
    }

    private func saveChanges() {
        member.name = name
        member.role = role
        member.email = email.isEmpty ? nil : email
        member.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FamilyMemberDetailView(member: FamilyMember(
            name: "Sarah Campbell",
            role: .medicalAdmin,
            email: "sarah@example.com",
            phoneNumber: "555-0123",
            isCurrentUser: true
        ))
    }
    .modelContainer(for: [
        ParentProfile.self, Appointment.self, Task.self,
        Document.self, FamilyMember.self, Expense.self,
        ExpenseAccount.self, UpdateFeedItem.self
    ], inMemory: true)
}
