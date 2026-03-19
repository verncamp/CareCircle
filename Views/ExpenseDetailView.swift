//
//  ExpenseDetailView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var expense: Expense
    @Query private var familyMembers: [FamilyMember]

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                detailsCard

                if !expense.notes.isEmpty {
                    notesCard
                }

                actionsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .adaptiveWidth()
        }
        .navigationTitle("Expense")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditExpenseView(expense: expense)
        }
        .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(expense)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(expense.title)\"?")
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            Image(systemName: iconForCategory(expense.category))
                .font(.system(size: 36))
                .foregroundStyle(.teal)
                .frame(width: 64, height: 64)
                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(expense.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(formatCurrency(expense.amount))
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text(expense.category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.teal.opacity(0.1), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Details")

            detailRow(icon: "calendar", label: "Date", value: expense.date.formatted(date: .long, time: .omitted))

            if let paidBy = expense.paidBy {
                detailRow(icon: "person.fill", label: "Paid by", value: paidBy.name)
            }

            detailRow(icon: "clock", label: "Recorded", value: expense.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
        .glassCard()
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
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
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes")
            Text(expense.notes)
                .font(.subheadline)
                .lineSpacing(4)
        }
        .glassCard()
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete Expense")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .glassCard()
    }

    private func iconForCategory(_ category: ExpenseCategory) -> String {
        iconForExpenseCategory(category)
    }
}

// MARK: - Edit Expense

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]

    @Bindable var expense: Expense

    @State private var title = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .other
    @State private var notes = ""
    @State private var date = Date()
    @State private var selectedMember: FamilyMember?

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Paid By") {
                    Picker("Family Member", selection: $selectedMember) {
                        Text("Select member").tag(nil as FamilyMember?)
                        ForEach(familyMembers) { member in
                            Text(member.name).tag(member as FamilyMember?)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(title.isEmpty || amount.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                title = expense.title
                amount = "\(expense.amount)"
                category = expense.category
                notes = expense.notes
                date = expense.date
                selectedMember = expense.paidBy
            }
        }
    }

    private func saveChanges() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        expense.title = title
        expense.amount = amountDecimal
        expense.category = category
        expense.notes = notes
        expense.date = date
        expense.paidBy = selectedMember
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ExpenseDetailView(expense: Expense(
            title: "Blood Pressure Monitor",
            amount: 89.99,
            category: .equipment,
            notes: "Omron Series 10 — recommended by Dr. Chen"
        ))
    }
    .modelContainer(for: [
        ParentProfile.self, Expense.self,
        FamilyMember.self, ExpenseAccount.self,
        Appointment.self, Task.self,
        Document.self, UpdateFeedItem.self
    ], inMemory: true)
}
