//
//  SettingsView.swift
//  CareCircle
//
//  Settings, account management, and app preferences.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"
    @Query private var profiles: [ParentProfile]
    @Query private var familyMembers: [FamilyMember]

    @State private var cloudKit = CloudKitAccountManager()
    @State private var showingEditProfile = false
    @State private var showingAddMember = false
    @State private var showingResetConfirm = false
    @State private var showingSignOutConfirm = false

    var currentUser: FamilyMember? {
        familyMembers.first { $0.isCurrentUser }
    }

    var profile: ParentProfile? {
        profiles.first
    }

    var isDemo: Bool {
        appMode == "demo"
    }

    var body: some View {
        NavigationStack {
            List {
                // Account
                accountSection

                // Care Circle Members
                membersSection

                // Parent Profile
                if let profile {
                    parentSection(profile)
                }

                // App Preferences
                preferencesSection

                // Danger Zone
                dangerSection
            }
            .navigationTitle("Settings")
            .task { await cloudKit.checkAccountStatus() }
            .sheet(isPresented: $showingEditProfile) {
                if let profile {
                    ParentProfileEditView(profile: profile)
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView()
            }
            .alert("Reset App", isPresented: $showingResetConfirm) {
                Button("Reset Everything", role: .destructive) {
                    SampleDataGenerator.clearAllData(modelContext: modelContext)
                    appMode = "none"
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all data and return to the welcome screen. This cannot be undone.")
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    SampleDataGenerator.clearAllData(modelContext: modelContext)
                    appMode = "none"
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will sign you out and delete all local data.")
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section {
            if let user = currentUser {
                HStack(spacing: 14) {
                    AvatarView(name: user.name, size: 50, gradient: [.teal, .mint])

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                        if let email = user.email, !email.isEmpty {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text(user.role.rawValue)
                            .font(.caption)
                            .foregroundStyle(.teal)
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text(isDemo ? "Demo User" : "No Account")
                            .font(.headline)
                        Text(isDemo ? "Exploring CareCircle" : "Sign in to save your data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if isDemo {
                Button {
                    SampleDataGenerator.clearAllData(modelContext: modelContext)
                    appMode = "signup"
                } label: {
                    Label("Sign Up for Real", systemImage: "person.badge.plus")
                        .foregroundStyle(.teal)
                }
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Members

    private var membersSection: some View {
        Section {
            ForEach(familyMembers) { member in
                HStack(spacing: 12) {
                    AvatarView(name: member.name, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(member.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if member.isCurrentUser {
                                Text("You")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.teal)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(.teal.opacity(0.1), in: Capsule())
                            }
                        }
                        Text(member.role.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let email = member.email, !email.isEmpty {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteMember)

            Button {
                showingAddMember = true
            } label: {
                Label("Invite Family Member", systemImage: "person.badge.plus")
                    .foregroundStyle(.teal)
            }
        } header: {
            Text("Care Circle (\(familyMembers.count) members)")
        }
    }

    private func deleteMember(at offsets: IndexSet) {
        for index in offsets {
            let member = familyMembers[index]
            if !member.isCurrentUser {
                // Delete orphaned expense account
                if let account = member.expenseAccount {
                    modelContext.delete(account)
                }
                modelContext.delete(member)
            }
        }
        try? modelContext.save()
    }

    // MARK: - Parent Profile

    private func parentSection(_ profile: ParentProfile) -> some View {
        Section("Care Recipient") {
            HStack(spacing: 12) {
                if let photoData = profile.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    AvatarView(name: profile.name, size: 44, gradient: [.teal, .mint])
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(profile.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Edit") {
                    showingEditProfile = true
                }
                .font(.subheadline)
            }

            NavigationLink(destination: ParentProfileView(profile: profile)) {
                Label("View Full Profile", systemImage: "person.text.rectangle")
            }

            if profile.healthKitEnabled {
                Label("Apple Health Connected", systemImage: "heart.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("App") {
            HStack(spacing: 12) {
                Image(systemName: cloudKit.isSignedIn ? "icloud.fill" : "icloud.slash")
                    .foregroundStyle(cloudKit.isSignedIn ? .teal : .red)
                VStack(alignment: .leading, spacing: 1) {
                    Text("iCloud Sync")
                        .font(.subheadline)
                    Text(cloudKit.statusDescription)
                        .font(.caption)
                        .foregroundStyle(cloudKit.isSignedIn ? .green : .red)
                }
                Spacer()
                if cloudKit.isSignedIn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            NavigationLink {
                notificationSettingsView
            } label: {
                Label("Notifications", systemImage: "bell.badge")
            }

            NavigationLink {
                aboutView
            } label: {
                Label("About CareCircle", systemImage: "info.circle")
            }

            HStack {
                Label("Version", systemImage: "gearshape")
                Spacer()
                Text("0.1.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        Section {
            if !isDemo {
                Button(role: .destructive) {
                    showingSignOutConfirm = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Reset App", systemImage: "trash")
            }
        } footer: {
            Text("Resetting deletes all local data and returns to the welcome screen.")
        }
    }

    // MARK: - Notification Settings

    private var notificationSettingsView: some View {
        NotificationSettingsView()
    }

    private var aboutView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.teal)

                Text("CareCircle")
                    .font(.title)
                    .fontWeight(.bold)

                Text("One place to coordinate care for the people who matter most.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Features")
                    featureItem("Appointments & checklists")
                    featureItem("Family task coordination")
                    featureItem("Document vault with scanning")
                    featureItem("Shared expense tracking")
                    featureItem("Apple Health vitals monitoring")
                    featureItem("On-device AI summaries")
                }
                .glassCard()
            }
            .padding()
            .adaptiveWidth()
        }
        .navigationTitle("About")
        .screenBackground()
    }

    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.teal)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, Document.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
