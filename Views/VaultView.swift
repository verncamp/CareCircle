//
//  VaultView.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI
import SwiftData

struct VaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]
    @State private var searchText = ""
    @State private var showingAddDocument = false
    
    var pinnedDocuments: [Document] {
        documents.filter { $0.isPinned }
    }
    
    var recentDocuments: [Document] {
        documents
            .filter { !$0.isPinned }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return recentDocuments
        } else {
            return recentDocuments.filter { doc in
                doc.title.localizedCaseInsensitiveContains(searchText) ||
                doc.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !pinnedDocuments.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedDocuments) { document in
                            DocumentRow(document: document)
                        }
                    }
                }
                
                Section("Recent") {
                    if filteredDocuments.isEmpty {
                        ContentUnavailableView(
                            "No Documents",
                            systemImage: "folder",
                            description: Text("Scan or add documents to keep important files organized")
                        )
                    } else {
                        ForEach(filteredDocuments) { document in
                            DocumentRow(document: document)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search documents")
            .navigationTitle("Vault")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showingAddDocument = true
                        }) {
                            Label("Add Document", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: {
                            // TODO: Implement document scanning
                        }) {
                            Label("Scan Document", systemImage: "doc.text.viewfinder")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                AddDocumentView()
            }
        }
    }
}

struct DocumentRow: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(document.category))
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 6) {
                    Text(document.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(document.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if document.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    func iconForCategory(_ category: DocumentCategory) -> String {
        switch category {
        case .insurance: return "shield.checkered"
        case .medical: return "heart.text.square"
        case .legal: return "doc.text"
        case .medication: return "pills"
        case .lab: return "chart.bar.doc.horizontal"
        case .vaccination: return "syringe"
        case .other: return "doc"
        }
    }
}

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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDocument()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    func saveDocument() {
        // For MVP, we'll just create a placeholder file URL
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
        .modelContainer(for: [Document.self, ParentProfile.self], inMemory: true)
}
