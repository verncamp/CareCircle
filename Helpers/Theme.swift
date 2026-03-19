//
//  Theme.swift
//  CareCircle
//
//  Design system: Glass cards, gradient backgrounds, consistent spacing.
//

import SwiftUI

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(padding: padding, cornerRadius: cornerRadius))
    }

    func screenBackground() -> some View {
        self.background {
            ZStack {
                Color(.systemGroupedBackground)
                LinearGradient(
                    colors: [
                        Color.teal.opacity(0.08),
                        Color.mint.opacity(0.05),
                        Color(red: 0.98, green: 0.88, blue: 0.82).opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Adaptive Content Width

struct AdaptiveContent: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveWidth() -> some View {
        modifier(AdaptiveContent())
    }
}

// MARK: - Async Helper
// Disambiguate Swift concurrency Task from the SwiftData Task model.
@discardableResult
func asyncRun(_ operation: @escaping @Sendable () async -> Void) -> _Concurrency.Task<Void, Never> {
    _Concurrency.Task(operation: operation)
}

// MARK: - Priority Helpers

extension TaskPriority {
    var color: Color {
        switch self {
        case .low:    return .secondary
        case .normal: return .teal
        case .high:   return .orange
        case .urgent: return .red
        }
    }

    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high:   return 1
        case .normal: return 2
        case .low:    return 3
        }
    }

    var icon: String {
        switch self {
        case .low:    return "arrow.down.circle"
        case .normal: return "minus.circle"
        case .high:   return "exclamationmark.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Currency Formatting

func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
}

// MARK: - Reusable Components

struct AvatarView: View {
    let name: String
    var size: CGFloat = 48
    var gradient: [Color] = [.teal, .mint]

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            if let action = action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
}
