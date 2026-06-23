//
//  Theme.swift
//  CareCircle
//
//  Design system: Glass cards, gradient backgrounds, consistent spacing.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Brand Tokens

extension Color {
    static let careClay = Color(red: 194 / 255, green: 97 / 255, blue: 61 / 255)
    static let careClayPressed = Color(red: 168 / 255, green: 79 / 255, blue: 48 / 255)
    static let careSage = Color(red: 63 / 255, green: 122 / 255, blue: 107 / 255)
    static let careApricot = Color(red: 232 / 255, green: 168 / 255, blue: 124 / 255)
    static let careOat = Color(red: 245 / 255, green: 240 / 255, blue: 232 / 255)
    static let careInk = Color(red: 36 / 255, green: 29 / 255, blue: 23 / 255)

    static var careTint: Color { careClay }
    static var careTintSoft: Color { careClay.opacity(0.10) }
    static var careAvatarGradient: [Color] { [.careClay, .careApricot] }
}

extension ShapeStyle where Self == Color {
    static var careTint: Color { Color.careTint }
    static var careSage: Color { Color.careSage }
    static var careApricot: Color { Color.careApricot }
    static var careInk: Color { Color.careInk }
    static var careTintSoft: Color { Color.careTintSoft }
}

#if canImport(UIKit)
extension UIColor {
    static let careTint = UIColor(red: 194 / 255, green: 97 / 255, blue: 61 / 255, alpha: 1)
    static let careSage = UIColor(red: 63 / 255, green: 122 / 255, blue: 107 / 255, alpha: 1)
}
#endif

// MARK: - Screen Background

struct CareCircleScreenWash: View {
    var isHero = false

    var body: some View {
        ZStack {
            Color.careOat
            LinearGradient(
                colors: [
                    Color.careClay.opacity(isHero ? 0.12 : 0.06),
                    Color.careSage.opacity(isHero ? 0.08 : 0.05),
                    Color.careApricot.opacity(isHero ? 0.18 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

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
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.24), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(padding: padding, cornerRadius: cornerRadius))
    }

    func screenBackground(isHero: Bool = false) -> some View {
        self.background {
            CareCircleScreenWash(isHero: isHero)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Brand Mark

struct CareCircleMark: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.10, to: 0.90)
                .stroke(
                    Color.careSage,
                    style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round)
                )
                .rotationEffect(.degrees(18))
                .frame(width: size, height: size)

            Circle()
                .fill(Color.careTint)
                .frame(width: size * 0.22, height: size * 0.22)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("CareCircle")
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

@discardableResult
func asyncRun(_ operation: @escaping @MainActor () async -> Void) -> _Concurrency.Task<Void, Never> {
    _Concurrency.Task { @MainActor in
        await operation()
    }
}

// MARK: - Priority Helpers

extension TaskPriority {
    var color: Color {
        switch self {
        case .low:    return .secondary
        case .normal: return .careTint
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

// MARK: - Category Icons

func iconForDocumentCategory(_ category: DocumentCategory) -> String {
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

func iconForExpenseCategory(_ category: ExpenseCategory) -> String {
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
    var gradient: [Color] = Color.careAvatarGradient

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
            .accessibilityLabel(name)
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
