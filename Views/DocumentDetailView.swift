//
//  DocumentDetailView.swift
//  CareCircle
//
//  Detail view for a stored document with PDF preview, metadata, and actions.
//

import SwiftUI
import SwiftData
import PDFKit

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var document: Document

    @State private var showingEdit = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: iconForCategory(document.category))
                        .font(.system(size: 40))
                        .foregroundStyle(.teal)
                        .frame(width: 72, height: 72)
                        .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Text(document.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Text(document.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.teal.opacity(0.1), in: Capsule())

                        if document.isPinned {
                            HStack(spacing: 4) {
                                Image(systemName: "pin.fill")
                                Text("Pinned")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.1), in: Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .glassCard()

                // PDF Preview
                if let data = document.fileData {
                    pdfPreview(data: data)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Details")

                    detailRow(label: "Created", value: document.createdAt.formatted(date: .long, time: .shortened))
                    detailRow(label: "Updated", value: document.updatedAt.formatted(date: .long, time: .shortened))

                    if !document.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tags")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            FlowLayout(spacing: 6) {
                                ForEach(document.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.secondary.opacity(0.1), in: Capsule())
                                }
                            }
                        }
                    }

                    if let extractedText = document.aiExtractedText, !extractedText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Extracted Text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(extractedText)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(10)
                        }
                    }
                }
                .glassCard()

                // Actions
                VStack(spacing: 10) {
                    Button {
                        document.isPinned.toggle()
                        try? modelContext.save()
                    } label: {
                        HStack {
                            Image(systemName: document.isPinned ? "pin.slash" : "pin")
                            Text(document.isPinned ? "Unpin Document" : "Pin Document")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)

                    if document.fileData != nil {
                        Button {
                            showingShareSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Document")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(.teal)
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Document")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                }
                .glassCard()
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .adaptiveWidth()
        }
        .navigationTitle("Document")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditDocumentView(document: document)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = document.fileData {
                ShareSheet(items: [data])
            }
        }
        .alert("Delete Document?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(document)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - PDF Preview

    private func pdfPreview(data: Data) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Preview")

            PDFKitView(data: data)
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .glassCard()
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    func iconForCategory(_ category: DocumentCategory) -> String {
        iconForDocumentCategory(category)
    }
}

// MARK: - PDF Kit Wrapper

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}
}

// MARK: - Edit Document Sheet

struct EditDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var document: Document

    @State private var title: String = ""
    @State private var category: DocumentCategory = .other
    @State private var isPinned: Bool = false
    @State private var tagText: String = ""

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

                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $tagText)
                            .textInputAutocapitalization(.never)
                        Button("Add") {
                            let tag = tagText.trimmingCharacters(in: .whitespaces)
                            guard !tag.isEmpty, !document.tags.contains(tag) else { return }
                            document.tags.append(tag)
                            tagText = ""
                        }
                        .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if !document.tags.isEmpty {
                        ForEach(document.tags, id: \.self) { tag in
                            Text(tag)
                        }
                        .onDelete { offsets in
                            document.tags.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Edit Document")
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
                title = document.title
                category = document.category
                isPinned = document.isPinned
            }
        }
    }

    private func saveChanges() {
        document.title = title
        document.category = category
        document.isPinned = isPinned
        document.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DocumentDetailView(document: Document(
            title: "Insurance Card - Blue Cross",
            category: .insurance,
            isPinned: true,
            tags: ["insurance", "2024"]
        ))
    }
    .modelContainer(for: [
        Document.self, ParentProfile.self,
        Appointment.self, Task.self,
        FamilyMember.self, Expense.self,
        ExpenseAccount.self, UpdateFeedItem.self
    ], inMemory: true)
}
