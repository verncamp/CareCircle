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
    @State private var selectedCategory: DocumentCategory?
    @State private var selectedDomain: DocumentDomain?
    @Query private var familyMembers: [FamilyMember]
    @State private var showingAddDocument = false
    @State private var showingScanner = false
    @State private var ai = AIAssistant()

    var pinnedDocuments: [Document] {
        let pinned = documents.filter { $0.isPinned }
        if let cat = selectedCategory { return pinned.filter { $0.category == cat } }
        if let domain = selectedDomain { return pinned.filter { $0.domain == domain } }
        return pinned
    }

    var filteredDocuments: [Document] {
        var unpinned = documents.filter { !$0.isPinned }
        if let cat = selectedCategory {
            unpinned = unpinned.filter { $0.category == cat }
        }
        if let domain = selectedDomain {
            unpinned = unpinned.filter { $0.domain == domain }
        }
        if searchText.isEmpty { return unpinned }
        return unpinned.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.domain.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var criticalDocuments: [Document] {
        documents
            .filter { $0.isCritical }
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }

    var expiringDocuments: [Document] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? .distantFuture
        return documents
            .filter {
                guard let expiry = $0.expiryDate else { return false }
                return expiry >= Date() && expiry <= cutoff
            }
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !criticalDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Critical Documents")
                                .padding(.horizontal, 4)

                            VStack(spacing: 8) {
                                ForEach(criticalDocuments.prefix(5)) { doc in
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        documentRow(doc)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !expiringDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Expiring Soon")
                                .padding(.horizontal, 4)

                            VStack(spacing: 8) {
                                ForEach(expiringDocuments.prefix(4)) { doc in
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        expiringRow(doc)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Pinned
                    if !pinnedDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Pinned")
                                .padding(.horizontal, 4)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(pinnedDocuments) { doc in
                                        NavigationLink(destination: DocumentDetailView(document: doc)) {
                                            pinnedCard(doc)
                                        }
                                        .buttonStyle(.plain)
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
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        documentRow(doc)
                                    }
                                    .buttonStyle(.plain)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        ForEach(DocumentCategory.allCases, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                HStack {
                                    Text(cat.rawValue)
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if let cat = selectedCategory {
                                Text(cat.rawValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Domains") {
                            selectedDomain = nil
                        }
                        ForEach(DocumentDomain.allCases, id: \.self) { domain in
                            Button {
                                selectedDomain = domain
                            } label: {
                                HStack {
                                    Text(domain.rawValue)
                                    if selectedDomain == domain {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                            if let domain = selectedDomain {
                                Text(domain.rawValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingAddDocument = true }) {
                            Label("Add Document", systemImage: "doc.badge.plus")
                        }
                        Button(action: { showingScanner = true }) {
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
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView { scannedData, pageCount in
                    saveScannedDocument(data: scannedData, pages: pageCount)
                }
            }
        }
    }

    // MARK: - Pinned Card

    private func pinnedCard(_ doc: Document) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconForCategory(doc.category))
                .font(.title2)
                .foregroundStyle(.careTint)
                .frame(width: 40, height: 40)
                .background(.careTint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

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
                .foregroundStyle(.careTint)
                .frame(width: 36, height: 36)
                .background(.careTint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(doc.domain.rawValue)
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
        .contextMenu {
            Button {
                doc.isPinned.toggle()
                try? modelContext.save()
            } label: {
                Label(doc.isPinned ? "Unpin" : "Pin", systemImage: doc.isPinned ? "pin.slash" : "pin")
            }
            Button(role: .destructive) {
                modelContext.delete(doc)
                try? modelContext.save()
                NotificationManager.resync(context: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func expiringRow(_ doc: Document) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.badge.clock")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(doc.domain.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let expiry = doc.expiryDate {
                Text(expiry.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .glassCard(padding: 12, cornerRadius: 14)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.careTint.opacity(0.5))

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

    private func saveScannedDocument(data: Data, pages: Int) {
        let document = Document(
            title: "Scanned Document (\(pages) page\(pages == 1 ? "" : "s"))",
            category: .other,
            countryProfileCode: documents.first?.parentProfile?.regionProfileCode ?? "US",
            fileURL: "scanned://\(UUID().uuidString)"
        )
        document.fileData = data
        document.parentProfile = documents.first?.parentProfile
        modelContext.insert(document)
        try? modelContext.save()
        NotificationManager.resync(context: modelContext)

        let author = familyMembers.first(where: \.isCurrentUser)?.name ?? "Someone"
        ActivityFeedHelper.logDocumentAdded(document, by: author, profile: document.parentProfile, context: modelContext)

        // Run OCR, then use AI to generate a descriptive title and category
        asyncRun { @MainActor in
            let text = await OCRHelper.extractText(from: data)
            if let text, !text.isEmpty {
                document.aiExtractedText = text
                try? modelContext.save()

                // AI labeling from extracted content
                if let label = await ai.labelDocument(from: text) {
                    if !label.title.isEmpty {
                        document.title = label.title
                    }
                    if let match = DocumentCategory.allCases.first(where: {
                        $0.rawValue.localizedCaseInsensitiveContains(label.category) ||
                        label.category.localizedCaseInsensitiveContains($0.rawValue)
                    }) {
                        document.category = match
                    }
                    document.updatedAt = Date()
                    try? modelContext.save()
                    NotificationManager.resync(context: modelContext)
                }
            }
        }
    }

    func iconForCategory(_ category: DocumentCategory) -> String {
        iconForDocumentCategory(category)
    }
}

// MARK: - Add Document Sheet

struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var parentProfiles: [ParentProfile]
    @Query private var familyMembers: [FamilyMember]

    @State private var title = ""
    @State private var category: DocumentCategory = .other
    @State private var domain: DocumentDomain = .other
    @State private var isPinned = false
    @State private var isCritical = false
    @State private var includeInEmergencyPacket = false
    @State private var issuer = ""
    @State private var memberOrPolicyId = ""
    @State private var hasExpiryDate = false
    @State private var expiryDate = Date()
    @State private var hasRenewalDate = false
    @State private var renewalDate = Date()
    @State private var ai = AIAssistant()
    @State private var showingFilePicker = false
    @State private var importedFileData: Data?
    @State private var importedFileName: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Details") {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _, newTitle in
                            guard ai.isAvailable, newTitle.count > 3 else { return }
                            asyncRun { @MainActor in
                                if let suggestion = await ai.suggestCategory(for: newTitle),
                                   let match = DocumentCategory.allCases.first(where: {
                                       $0.rawValue.localizedCaseInsensitiveContains(suggestion) ||
                                       suggestion.localizedCaseInsensitiveContains($0.rawValue)
                                   }) {
                                    category = match
                                }
                            }
                        }

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
                    Toggle("Include in emergency packet", isOn: $includeInEmergencyPacket)
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
                }

                Section("File") {
                    if let fileName = importedFileName {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.careTint)
                            Text(fileName)
                                .font(.subheadline)
                            Spacer()
                            Button("Remove") {
                                importedFileData = nil
                                importedFileName = nil
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label(importedFileData == nil ? "Attach File" : "Replace File",
                              systemImage: "paperclip")
                    }
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
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .image, .jpeg, .png],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    importedFileData = try? Data(contentsOf: url)
                    importedFileName = url.lastPathComponent
                    if title.isEmpty {
                        title = url.deletingPathExtension().lastPathComponent
                    }
                }
            }
            .onChange(of: isCritical) { _, newValue in
                if newValue {
                    includeInEmergencyPacket = true
                }
            }
        }
    }

    func saveDocument() {
        let document = Document(
            title: title,
            category: category,
            domain: domain,
            countryProfileCode: parentProfiles.first?.regionProfileCode ?? "US",
            fileURL: importedFileName ?? "manual://\(UUID().uuidString)",
            isPinned: isPinned,
            issuer: issuer.isEmpty ? nil : issuer,
            memberOrPolicyId: memberOrPolicyId.isEmpty ? nil : memberOrPolicyId,
            expiryDate: hasExpiryDate ? expiryDate : nil,
            renewalDate: hasRenewalDate ? renewalDate : nil,
            isCritical: isCritical,
            includeInEmergencyPacket: includeInEmergencyPacket
        )
        document.fileData = importedFileData
        document.parentProfile = parentProfiles.first
        modelContext.insert(document)
        try? modelContext.save()
        NotificationManager.resync(context: modelContext)

        let author = familyMembers.first(where: \.isCurrentUser)?.name ?? "Someone"
        ActivityFeedHelper.logDocumentAdded(document, by: author, profile: parentProfiles.first, context: modelContext)

        // Run OCR + AI labeling on imported PDFs in background
        if let data = importedFileData {
            asyncRun { @MainActor in
                let text = await OCRHelper.extractText(from: data)
                if let text, !text.isEmpty {
                    document.aiExtractedText = text
                    try? modelContext.save()
                }
            }
        }

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
