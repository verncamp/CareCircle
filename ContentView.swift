//
//  ContentView.swift
//  CareCircle
//

import SwiftUI
import SwiftData

// MARK: - App Router

struct AppRouter: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"
    @Query private var profiles: [ParentProfile]

    var body: some View {
        Group {
            switch appMode {
            case "demo":
                MainContentView(isDemo: true)
            case "signup":
                OnboardingView()
            case "real":
                if profiles.isEmpty {
                    BootstrapView()
                } else {
                    MainContentView(isDemo: false)
                }
            default:
                BootstrapView()
            }
        }
    }
}

struct BootstrapView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"
    @Query private var profiles: [ParentProfile]
    @State private var didBootstrap = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.12),
                    Color.mint.opacity(0.08),
                    Color(red: 0.98, green: 0.88, blue: 0.82).opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(.teal)

                Text("Preparing CareCircle")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Launching a working workspace first. You can customize account and family details after the app opens.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                ProgressView()
                    .tint(.teal)

                Button("Open manual setup instead") {
                    appMode = "signup"
                }
                .font(.subheadline)
                .foregroundStyle(.teal)
            }
        }
        .onAppear {
            guard !didBootstrap else { return }
            didBootstrap = true

            if profiles.isEmpty {
                SampleDataGenerator.generateSampleData(modelContext: modelContext)
                appMode = "demo"
            } else {
                appMode = "real"
            }
        }
    }
}

// MARK: - Tab Model

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case today = "Today"
    case calendar = "Calendar"
    case vault = "Vault"
    case family = "Family"
    case finances = "Finances"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today:    return "house.fill"
        case .calendar: return "calendar"
        case .vault:    return "folder.fill"
        case .family:   return "person.3.fill"
        case .finances: return "dollarsign.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Main Content

struct MainContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"
    @State private var selectedTab: AppTab = .today

    let isDemo: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Demo banner
            if isDemo {
                demoBanner
            }

            // Main app
            Group {
                if horizontalSizeClass == .regular {
                    adaptiveLayout
                } else {
                    compactLayout
                }
            }
        }
        .tint(.teal)
    }

    private var demoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle.fill")
                .font(.subheadline)
            Text("Demo Mode")
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Button("Sign Up") {
                SampleDataGenerator.clearAllData(modelContext: modelContext)
                appMode = "signup"
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.white.opacity(0.25), in: Capsule())

            Button {
                SampleDataGenerator.clearAllData(modelContext: modelContext)
                appMode = "none"
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.teal.gradient)
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
        case .settings: SettingsView()
        }
    }
}

// MARK: - Sidebar

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

#Preview("Welcome") {
    AppRouter()
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, Document.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
