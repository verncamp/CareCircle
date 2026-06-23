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
                        .foregroundStyle(.careTint)
                        .frame(width: 72, height: 72)
                        .background(.careTint.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

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
                            .background(.careTint.opacity(0.1), in: Capsule())

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
                        if document.isCritical {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Critical")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.1), in: Capsule())
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
                    detailRow(label: "Domain", value: document.domain.rawValue)
                    detailRow(label: "Country", value: document.countryProfileCode)

                    if let issuer = document.issuer, !issuer.isEmpty {
                        detailRow(label: "Issuer", value: issuer)
                    }

                    if let memberOrPolicyId = document.memberOrPolicyId, !memberOrPolicyId.isEmpty {
                        detailRow(label: "Member / Policy ID", value: memberOrPolicyId)
                    }

                    if let expiryDate = document.expiryDate {
                        detailRow(label: "Expiry", value: expiryDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    if let renewalDate = document.renewalDate {
                        detailRow(label: "Renewal", value: renewalDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    if document.isCritical || document.includeInEmergencyPacket {
                        HStack(spacing: 8) {
                            if document.isCritical {
                                Label("Critical", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if document.includeInEmergencyPacket {
                                Label("Emergency Packet", systemImage: "cross.case.fill")
                                    .font(.caption)
                                    .foregroundStyle(.careTint)
                            }
                        }
                    }

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
                    .tint(.careTint)

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
                        .tint(.careTint)
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
                NotificationManager.resync(context: modelContext)
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
    @State private var domain: DocumentDomain = .other
    @State private var isPinned: Bool = false
    @State private var isCritical: Bool = false
    @State private var issuer: String = ""
    @State private var memberOrPolicyId: String = ""
    @State private var hasExpiryDate: Bool = false
    @State private var expiryDate: Date = Date()
    @State private var hasRenewalDate: Bool = false
    @State private var renewalDate: Date = Date()
    @State private var tagText: String = ""
    @State private var tags: [String] = []
    @State private var includeInEmergencyPacket: Bool = false

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

                    Picker("Domain", selection: $domain) {
                        ForEach(DocumentDomain.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }

                    Toggle("Pin to top", isOn: $isPinned)
                    Toggle("Critical document", isOn: $isCritical)
                }

                Section("Coverage Details") {
                    TextField("Issuer (optional)", text: $issuer)
                    TextField("Member/Policy ID (optional)", text: $memberOrPolicyId)
                    Toggle("Has expiry date", isOn: $hasExpiryDate)
                    if hasExpiryDate {
                        DatePicker("Expiry date", selection: $expiryDate, displayedComponents: .date)
                    }
                    Toggle("Has renewal date", isOn: $hasRenewalDate)
                    if hasRenewalDate {
                        DatePicker("Renewal date", selection: $renewalDate, displayedComponents: .date)
                    }
                    Toggle("Include in emergency packet", isOn: $includeInEmergencyPacket)
                }

                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $tagText)
                            .textInputAutocapitalization(.never)
                        Button("Add") {
                            let tag = tagText.trimmingCharacters(in: .whitespaces)
                            guard !tag.isEmpty, !tags.contains(tag) else { return }
                            tags.append(tag)
                            tagText = ""
                        }
                        .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if !tags.isEmpty {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                        }
                        .onDelete { offsets in
                            tags.remove(atOffsets: offsets)
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
                domain = document.domain
                isPinned = document.isPinned
                isCritical = document.isCritical
                issuer = document.issuer ?? ""
                memberOrPolicyId = document.memberOrPolicyId ?? ""
                hasExpiryDate = document.expiryDate != nil
                expiryDate = document.expiryDate ?? Date()
                hasRenewalDate = document.renewalDate != nil
                renewalDate = document.renewalDate ?? Date()
                includeInEmergencyPacket = document.includeInEmergencyPacket
                tags = document.tags
            }
        }
    }

    private func saveChanges() {
        document.title = title
        document.category = category
        document.domain = domain
        document.isPinned = isPinned
        document.isCritical = isCritical
        document.includeInEmergencyPacket = includeInEmergencyPacket
        document.issuer = issuer.isEmpty ? nil : issuer
        document.memberOrPolicyId = memberOrPolicyId.isEmpty ? nil : memberOrPolicyId
        document.expiryDate = hasExpiryDate ? expiryDate : nil
        document.renewalDate = hasRenewalDate ? renewalDate : nil
        document.tags = tags
        document.updatedAt = Date()
        try? modelContext.save()
        NotificationManager.resync(context: modelContext)
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
