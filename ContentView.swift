//
//  ContentView.swift
//  CareCircle
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case today = "Today"
    case calendar = "Calendar"
    case vault = "Vault"
    case family = "Family"
    case finances = "Finances"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today:    return "house.fill"
        case .calendar: return "calendar"
        case .vault:    return "folder.fill"
        case .family:   return "person.3.fill"
        case .finances: return "dollarsign.circle.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: AppTab = .today

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                adaptiveLayout
            } else {
                compactLayout
            }
        }
        .tint(.teal)
    }

    // iPad / Mac: sidebar
    private var adaptiveLayout: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            tabContent(selectedTab)
        }
    }

    // iPhone: tabs
    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabContent(tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
        case .today:    TodayView()
        case .calendar: CalendarView()
        case .vault:    VaultView()
        case .family:   FamilyView()
        case .finances: FinancesView()
        }
    }
}

// Separate struct avoids the List(selection:) availability issue
struct SidebarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        List {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .listRowBackground(
                    selectedTab == tab
                        ? Color.teal.opacity(0.12)
                        : Color.clear
                )
            }
        }
        .navigationTitle("CareCircle")
    }
}

#Preview("iPhone") {
    ContentView()
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, Document.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ])
}

#Preview("iPad") {
    ContentView()
        .previewDevice("iPad Pro (12.9-inch)")
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, Document.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ])
}
