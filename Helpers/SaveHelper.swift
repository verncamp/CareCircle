//
//  SaveHelper.swift
//  CareCircle
//
//  Wraps modelContext.save() with user-visible error feedback.
//

import SwiftUI
import SwiftData

// MARK: - Save with Error Feedback

extension ModelContext {
    /// Save and return success. Callers can show an alert on failure.
    @discardableResult
    func safeSave() -> Bool {
        do {
            try save()
            return true
        } catch {
            print("SwiftData save failed: \(error)")
            return false
        }
    }
}

// MARK: - Save Error Banner

struct SaveErrorBanner: ViewModifier {
    @Binding var showError: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if showError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Failed to save changes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(radius: 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showError = false }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.3), value: showError)
    }
}

extension View {
    func saveErrorBanner(show: Binding<Bool>) -> some View {
        modifier(SaveErrorBanner(showError: show))
    }
}
