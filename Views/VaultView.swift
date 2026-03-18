//
//  VaultView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

struct VaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.createdAt, order: .reverse) private var documents: [Document]
    @State private var searchText = ""
    @State private var showingAddDocument = false

    var pinnedDocuments: [Document] {
        documents.filter { $0.isPinned }
    }

    var filteredDocuments: [Document] {
        let unpinned = documents.filter { !$0.isPinned }
        if searchText.isEmpty { return unpinned }
        return unpinned.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Pinned
                    if !pinnedDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Pinned")
                                .padding(.horizontal, 4)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(pinnedDocuments) { doc in
                                        pinnedCard(doc)
                                    }
                                }
                            }
                        }
                    }

                    // All Documents
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "All Documents")

                        if filteredDocuments.isEmpty && pinnedDocuments.isEmpty {
                            emptyState
                        } else if filteredDocuments.isEmpty {
                            Text("No other documents")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(filteredDocuments) { doc in
                                    documentRow(doc)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .adaptiveWidth()
            }
            .searchable(text: $searchText, prompt: "Search documents")
            .navigationTitle("Vault")
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingAddDocument = true }) {
                            Label("Add Document", systemImage: "doc.badge.plus")
                        }
                        Button(action: {}) {
                            Label("Scan Document", systemImage: "doc.text.viewfinder")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                AddDocumentView()
            }
        }
    }

    // MARK: - Pinned Card

    private func pinnedCard(_ doc: Document) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconForCategory(doc.category))
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 40, height: 40)
                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(doc.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            Text(doc.category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 130, alignment: .leading)
        .glassCard(padding: 14, cornerRadius: 16)
    }

    // MARK: - Document Row

    private func documentRow(_ doc: Document) -> some View {
        HStack(spacing: 14) {
            Image(systemName: iconForCategory(doc.category))
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 36, height: 36)
                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(doc.category.rawValue)
                    Text("·")
                    Text(doc.createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if doc.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .glassCard(padding: 12, cornerRadius: 14)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.teal.opacity(0.5))

            Text("No Documents Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Store important documents like insurance cards, medication lists, and legal papers")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    func iconForCategory(_ category: DocumentCategory) -> String {
        switch category {
        case .insurance:   return "shield.checkered"
        case .medical:     return "heart.text.square"
        case .legal:       return "doc.text"
        case .medication:  return "pills"
        case .lab:         return "chart.bar.doc.horizontal"
        case .vaccination: return "syringe"
        case .other:       return "doc"
        }
    }
}

// MARK: - Add Document Sheet

struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]

    @State private var title = ""
    @State private var category: DocumentCategory = .other
    @State private var isPinned = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Details") {
                    TextField("Title", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(DocumentCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    Toggle("Pin to top", isOn: $isPinned)
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDocument() }
                        .disabled(title.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveDocument() {
        let document = Document(
            title: title,
            category: category,
            fileURL: "placeholder://\(UUID().uuidString)",
            isPinned: isPinned
        )
        document.parentProfile = parentProfiles.first
        modelContext.insert(document)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    VaultView()
        .modelContainer(for: [
            Document.self, ParentProfile.self,
            Appointment.self, Task.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
