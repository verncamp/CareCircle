//
//  TaskDetailView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: Task
    @Query private var familyMembers: [FamilyMember]

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerCard

                // Details
                detailsCard

                // Description
                if !task.taskDescription.isEmpty {
                    descriptionCard
                }

                // Actions
                actionsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .adaptiveWidth()
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditTaskView(task: task)
        }
        .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(task)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(task.title)\"?")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(task.isCompleted ? .green : task.priority.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .strikethrough(task.isCompleted)

                    HStack(spacing: 6) {
                        Image(systemName: task.priority.icon)
                            .foregroundStyle(task.priority.color)
                        Text(task.priority.rawValue.capitalized)
                            .foregroundStyle(task.priority.color)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                }

                Spacer()
            }

            // Toggle completion
            Button {
                withAnimation(.spring(response: 0.3)) {
                    task.isCompleted.toggle()
                    task.updatedAt = Date()
                    try? modelContext.save()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    Text(task.isCompleted ? "Mark Incomplete" : "Mark Complete")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(task.isCompleted ? .orange : .green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    (task.isCompleted ? Color.orange : Color.green).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            }
        }
        .glassCard()
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Details")

            if let assignee = task.assignedTo {
                detailRow(icon: "person.fill", label: "Assigned to", value: assignee.name)
            } else {
                detailRow(icon: "person.fill", label: "Assigned to", value: "Unassigned", valueColor: .orange)
            }

            if let dueDate = task.dueDate {
                let isPastDue = dueDate < Date() && !task.isCompleted
                detailRow(
                    icon: "calendar",
                    label: "Due date",
                    value: dueDate.formatted(date: .long, time: .omitted),
                    valueColor: isPastDue ? .red : .primary
                )
            }

            detailRow(icon: "clock", label: "Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
            detailRow(icon: "arrow.clockwise", label: "Updated", value: task.updatedAt.formatted(date: .abbreviated, time: .shortened))
        }
        .glassCard()
    }

    private func detailRow(icon: String, label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.teal)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Description

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Description")

            Text(task.taskDescription)
                .font(.subheadline)
                .lineSpacing(4)
        }
        .glassCard()
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete Task")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .glassCard()
    }
}

// MARK: - Edit Task

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]

    @Bindable var task: Task

    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var priority: TaskPriority = .normal
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var assignee: FamilyMember?

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $taskDescription)

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
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(title.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                title = task.title
                taskDescription = task.taskDescription
                priority = task.priority
                hasDueDate = task.dueDate != nil
                dueDate = task.dueDate ?? Date()
                assignee = task.assignedTo
            }
        }
    }

    private func saveChanges() {
        task.title = title
        task.taskDescription = taskDescription
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.assignedTo = assignee
        task.updatedAt = Date()
        try? modelContext.save()
        NotificationManager.scheduleTaskReminder(for: task)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: Task(
            title: "Pick up prescription",
            taskDescription: "Get the new blood pressure medication from CVS on Main St. Insurance card is in the vault.",
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            priority: .high
        ))
    }
    .modelContainer(for: [
        ParentProfile.self, Appointment.self, Task.self,
        Document.self, FamilyMember.self, Expense.self,
        ExpenseAccount.self, UpdateFeedItem.self
    ], inMemory: true)
}
