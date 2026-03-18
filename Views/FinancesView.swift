//
//  FinancesView.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI
import SwiftData

struct FinancesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    @Query private var expenses: [Expense]
    @Query private var familyMembers: [FamilyMember]
    
    @State private var showingAddExpense = false
    
    var activeProfile: ParentProfile? {
        parentProfiles.first
    }
    
    var totalPoolBalance: Decimal {
        familyMembers.compactMap { $0.expenseAccount?.balance }.reduce(0, +)
    }
    
    var totalContributed: Decimal {
        familyMembers.compactMap { $0.expenseAccount?.totalContributed }.reduce(0, +)
    }
    
    var totalSpent: Decimal {
        expenses.map { $0.amount }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Home Account Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Home Account")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Total Pool")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatCurrency(totalPoolBalance))
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Contributed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatCurrency(totalContributed))
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.green)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Spent")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatCurrency(totalSpent))
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Family Member Accounts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Family Contributions")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        if familyMembers.isEmpty {
                            Text("No family members yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(familyMembers) { member in
                                FamilyAccountRow(member: member)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Recent Expenses
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Expenses")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddExpense = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        if expenses.isEmpty {
                            Text("No expenses recorded")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(expenses.sorted(by: { $0.date > $1.date }).prefix(10)) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Finances")
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

struct FamilyAccountRow: View {
    let member: FamilyMember
    
    var balance: Decimal {
        member.expenseAccount?.balance ?? 0
    }
    
    var contributed: Decimal {
        member.expenseAccount?.totalContributed ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(member.role.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(balance))
                    .font(.body)
                    .fontWeight(.semibold)
                Text("contributed \(formatCurrency(contributed))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(expense.category))
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                HStack(spacing: 6) {
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let paidBy = expense.paidBy {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(paidBy.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(expense.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    func iconForCategory(_ category: ExpenseCategory) -> String {
        switch category {
        case .medical: return "cross.case.fill"
        case .medication: return "pills.fill"
        case .utilities: return "bolt.fill"
        case .groceries: return "cart.fill"
        case .homeAide: return "person.fill"
        case .transportation: return "car.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .other: return "tag.fill"
        }
    }
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
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
        
        modelContext.insert(expense)
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    FinancesView()
        .modelContainer(for: [ParentProfile.self, Expense.self, FamilyMember.self, ExpenseAccount.self], inMemory: true)
}
