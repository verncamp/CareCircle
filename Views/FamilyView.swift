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
    @State private var showingAddTask = false
    @State private var taskFilter: TaskFilter = .open

    enum TaskFilter: String, CaseIterable {
        case open = "Open"
        case completed = "Done"
        case all = "All"
    }

    var filteredTasks: [Task] {
        switch taskFilter {
        case .open: return tasks.filter { !$0.isCompleted }
        case .completed: return tasks.filter { $0.isCompleted }
        case .all: return Array(tasks)
        }
    }

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

                    // Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionHeader(title: "Tasks")
                            Spacer()
                            Button {
                                showingAddTask = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.teal)
                            }
                        }

                        Picker("Filter", selection: $taskFilter) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

                        if filteredTasks.isEmpty {
                            Text(taskFilter == .open ? "No open tasks" : "No tasks")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(filteredTasks.prefix(10)) { task in
                                taskRow(task)
                            }
                        }
                    }
                    .glassCard()
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
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
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
            Button {
                withAnimation(.spring(response: 0.3)) {
                    task.isCompleted.toggle()
                    task.updatedAt = Date()
                    try? modelContext.save()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : task.priority.color.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 6) {
                    if let assigned = task.assignedTo {
                        Text(assigned.name)
                    } else {
                        Text("Unassigned").foregroundStyle(.orange)
                    }
                    if let due = task.dueDate {
                        Text("·")
                        Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: task.priority.icon)
                .foregroundStyle(task.priority.color)
                .font(.caption)
        }
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(task)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
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

// MARK: - Add Task Sheet

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    @Query private var familyMembers: [FamilyMember]

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .normal
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var assignee: FamilyMember?

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description)

                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(TaskPriority.low)
                        Text("Normal").tag(TaskPriority.normal)
                        Text("High").tag(TaskPriority.high)
                        Text("Urgent").tag(TaskPriority.urgent)
                    }
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Assign To") {
                    Picker("Family Member", selection: $assignee) {
                        Text("Unassigned").tag(nil as FamilyMember?)
                        ForEach(familyMembers) { member in
                            Text(member.name).tag(member as FamilyMember?)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTask() }
                        .disabled(title.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveTask() {
        let task = Task(
            title: title,
            taskDescription: description,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority
        )
        task.assignedTo = assignee
        task.parentProfile = parentProfiles.first
        modelContext.insert(task)
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
