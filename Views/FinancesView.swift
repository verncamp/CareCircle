//
//  FinancesView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct FinancesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var familyMembers: [FamilyMember]

    @State private var showingAddExpense = false
    @State private var showingContribute = false

    var totalPoolBalance: Decimal {
        familyMembers.compactMap { $0.expenseAccount?.balance }.reduce(0, +)
    }

    var totalContributed: Decimal {
        familyMembers.compactMap { $0.expenseAccount?.totalContributed }.reduce(0, +)
    }

    var totalSpent: Decimal {
        familyMembers.compactMap { $0.expenseAccount?.totalSpent }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    balanceCard

                    if !familyMembers.isEmpty {
                        contributionsSection
                    }

                    if !expenses.isEmpty {
                        categoryBreakdown
                    }

                    expensesSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .adaptiveWidth()
            }
            .navigationTitle("Finances")
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingAddExpense = true }) {
                            Label("Add Expense", systemImage: "creditcard")
                        }
                        Button(action: { showingContribute = true }) {
                            Label("Fund Account", systemImage: "banknote")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingContribute) {
                ContributeView()
            }
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Home Account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formatCurrency(totalPoolBalance))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                    Text(formatCurrency(totalContributed))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Contributed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.red)
                    Text(formatCurrency(totalSpent))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .glassCard()
    }

    // MARK: - Contributions

    private var contributionsSection: some View {
        let maxContribution = max(
            familyMembers.compactMap { $0.expenseAccount?.totalContributed }.max() ?? 0,
            1
        )

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Contributions")

            ForEach(familyMembers) { member in
                let contributed = member.expenseAccount?.totalContributed ?? 0
                let fraction = Double(truncating: (contributed / maxContribution) as NSDecimalNumber)

                VStack(spacing: 6) {
                    HStack {
                        Text(member.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatCurrency(contributed))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(.teal.gradient)
                                .frame(width: geo.size.width * max(fraction, 0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.vertical, 4)
            }
        }
        .glassCard()
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        let sorted = grouped
            .map { (category: $0.key, total: $0.value.map(\.amount).reduce(0, +)) }
            .sorted { $0.total > $1.total }

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "By Category")

            ForEach(sorted.prefix(5), id: \.category) { item in
                HStack(spacing: 12) {
                    Image(systemName: iconForCategory(item.category))
                        .foregroundStyle(.teal)
                        .frame(width: 24)

                    Text(item.category.rawValue)
                        .font(.subheadline)

                    Spacer()

                    Text(formatCurrency(item.total))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Expenses List

    private var expensesSection: some View {
        let recent = Array(expenses.prefix(10))

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Expenses")

            if recent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.teal.opacity(0.5))
                    Text("No expenses recorded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(recent) { expense in
                        NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                        HStack(spacing: 12) {
                            Image(systemName: iconForCategory(expense.category))
                                .font(.body)
                                .foregroundStyle(.teal)
                                .frame(width: 32, height: 32)
                                .background(
                                    .teal.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                HStack(spacing: 4) {
                                    Text(expense.category.rawValue)
                                    if let paidBy = expense.paidBy {
                                        Text("·")
                                        Text(paidBy.name)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatCurrency(expense.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(expense)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .glassCard()
    }

    func iconForCategory(_ category: ExpenseCategory) -> String {
        switch category {
        case .medical:        return "cross.case.fill"
        case .medication:     return "pills.fill"
        case .utilities:      return "bolt.fill"
        case .groceries:      return "cart.fill"
        case .homeAide:       return "person.fill"
        case .transportation: return "car.fill"
        case .equipment:      return "wrench.and.screwdriver.fill"
        case .other:          return "tag.fill"
        }
    }
}

// MARK: - Add Expense Sheet

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]
    @Query private var parentProfiles: [ParentProfile]

    @State private var title = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .other
    @State private var notes = ""
    @State private var selectedMember: FamilyMember?
    @State private var date = Date()

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
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExpense() }
                        .disabled(title.isEmpty || amount.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveExpense() {
        guard let amountDecimal = Decimal(string: amount) else { return }

        let expense = Expense(
            title: title,
            amount: amountDecimal,
            category: category,
            date: date,
            notes: notes
        )
        expense.paidBy = selectedMember
        expense.parentProfile = parentProfiles.first

        // Deduct from payer's account
        if let account = selectedMember?.expenseAccount {
            account.spend(amount: amountDecimal)
        }

        modelContext.insert(expense)
        try? modelContext.save()

        let author = familyMembers.first(where: \.isCurrentUser)?.name ?? "Someone"
        ActivityFeedHelper.logExpenseAdded(expense, by: author, profile: parentProfiles.first, context: modelContext)
        dismiss()
    }
}

// MARK: - Contribute View

struct ContributeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]
    @Query private var parentProfiles: [ParentProfile]

    @State private var amount = ""
    @State private var selectedMember: FamilyMember?

    var body: some View {
        NavigationStack {
            Form {
                Section("Contribution") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("From", selection: $selectedMember) {
                        Text("Select member").tag(nil as FamilyMember?)
                        ForEach(familyMembers) { member in
                            HStack {
                                Text(member.name)
                                if let balance = member.expenseAccount?.balance {
                                    Text("(\(formatCurrency(balance)))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(member as FamilyMember?)
                        }
                    }
                }

                if let member = selectedMember, let account = member.expenseAccount {
                    Section("Current Balance") {
                        HStack {
                            Text("Balance")
                            Spacer()
                            Text(formatCurrency(account.balance))
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("Total Contributed")
                            Spacer()
                            Text(formatCurrency(account.totalContributed))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Fund Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Contribute") { saveContribution() }
                        .disabled(amount.isEmpty || selectedMember == nil)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedMember = familyMembers.first(where: \.isCurrentUser)
            }
        }
    }

    private func saveContribution() {
        guard let amountDecimal = Decimal(string: amount),
              let member = selectedMember,
              let account = member.expenseAccount else { return }

        account.contribute(amount: amountDecimal)
        try? modelContext.save()

        let author = familyMembers.first(where: \.isCurrentUser)?.name ?? "Someone"
        ActivityFeedHelper.logNote(
            "\(member.name) contributed \(formatCurrency(amountDecimal)) to the care fund",
            by: author,
            profile: parentProfiles.first,
            context: modelContext
        )
        dismiss()
    }
}

#Preview {
    FinancesView()
        .modelContainer(for: [
            ParentProfile.self, Expense.self,
            FamilyMember.self, ExpenseAccount.self,
            Appointment.self, Task.self,
            Document.self, UpdateFeedItem.self
        ], inMemory: true)
}
