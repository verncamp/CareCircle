//
//  OnboardingView.swift
//  CareCircle
//
//  Step-by-step setup: account → parent info → confirm.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"

    @State private var healthKit = HealthKitManager()
    @State private var ai = AIAssistant()
    @State private var step = 0
    @State private var selectedRegion: RegionProfile = RegionProfileResolver.suggested()

    // Account (Step 1)
    @State private var userName = ""
    @State private var userEmail = ""

    // Parent (Step 2)
    @State private var parentName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -75, to: Date()) ?? Date()
    @State private var bloodType = ""
    @State private var allergies = ""
    @State private var primaryPhysician = ""
    @State private var userRole: FamilyRole = .medicalAdmin
    @State private var connectHealth = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            CareCircleScreenWash(isHero: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.careTint : Color.careTint.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Steps
                Group {
                    switch step {
                    case 0: accountStep
                    case 1: regionStep
                    case 2: parentStep
                    default: confirmStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

                // Navigation
                VStack(spacing: 8) {
                    HStack {
                        if step > 0 {
                            Button("Back") {
                                withAnimation { step -= 1 }
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if step < totalSteps - 1 {
                            Button {
                                withAnimation { step += 1 }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Next")
                                    Image(systemName: "arrow.right")
                                }
                                .fontWeight(.semibold)
                            }
                            .disabled(!canAdvance)
                        }
                    }

                    // Escape hatch so the app is always usable even if onboarding UI is blocked
                    Button {
                        SampleDataGenerator.generateSampleData(modelContext: modelContext)
                        appMode = "demo"
                    } label: {
                        Text("Skip for now (load demo data)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .tint(.careTint)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return !userName.isEmpty
        case 1: return true
        case 2: return !parentName.isEmpty
        default: return true
        }
    }

    // MARK: - Step 1: Account

    private var accountStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Your Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("CareCircle stores your care information on this iPhone by default. Start with your name and optional contact details.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.title)
                            .foregroundStyle(.careTint)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local Storage")
                                .font(.headline)
                            Text("Stored on this iPhone")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Appointments, notes, documents, and emergency information stay on this iPhone unless you explicitly share or export them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                // Name & email
                VStack(spacing: 16) {
                    TextField("Your full name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()

                    TextField("Email address (optional)", text: $userEmail)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Step 2: Region

    private var regionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where do you manage care?")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("We preconfigure document and reminder templates for your region. You can change this later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(RegionProfile.allCases, id: \.self) { region in
                        Button {
                            selectedRegion = region
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(region.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(region.healthCoverageLabel)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedRegion == region ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedRegion == region ? .careTint : .secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("AI behavior on this iPhone")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(ai.availabilityState.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(24)
        }
    }

    // MARK: - Step 2: Parent Info

    private var parentStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Who are you caring for?")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Start with the basics. You can add more details later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    TextField("Parent's name", text: $parentName)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)

                    TextField("Blood type (optional)", text: $bloodType)
                        .textFieldStyle(.roundedBorder)

                    TextField("Known allergies (optional)", text: $allergies)
                        .textFieldStyle(.roundedBorder)

                    TextField("Primary physician (optional)", text: $primaryPhysician)
                        .textFieldStyle(.roundedBorder)

                    Picker("Your role", selection: $userRole) {
                        ForEach(FamilyRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }

                    Toggle(isOn: $connectHealth) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect Apple Health")
                                .font(.subheadline)
                            Text("Read vitals from the Health app on this iPhone")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.careTint)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.careTint)

                    Text("You're all set!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Your care information stays on this iPhone by default.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Summary")
                    summaryRow(label: "You", value: userName)
                    if !userEmail.isEmpty {
                        summaryRow(label: "Email", value: userEmail)
                    }
                    summaryRow(label: "Role", value: userRole.rawValue)
                    summaryRow(label: "Care recipient", value: parentName)
                    summaryRow(label: "Region", value: selectedRegion.rawValue)
                    summaryRow(label: "Storage", value: "On this iPhone")
                    summaryRow(label: "Apple Health", value: connectHealth ? "Connected" : "Not connected")
                }
                .glassCard()

                Button {
                    createProfile()
                } label: {
                    Text("Create Care Circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.careTint)
                .controlSize(.large)
                .disabled(parentName.isEmpty || userName.isEmpty)
            }
            .padding(24)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Create Profile

    private func createProfile() {
        let profile = ParentProfile(
            name: parentName,
            regionProfileCode: selectedRegion.countryCode,
            dateOfBirth: dateOfBirth,
            bloodType: bloodType.isEmpty ? nil : bloodType,
            allergies: allergies.isEmpty ? nil : allergies,
            primaryPhysician: primaryPhysician.isEmpty ? nil : primaryPhysician,
            healthKitEnabled: connectHealth
        )
        modelContext.insert(profile)

        let member = FamilyMember(
            name: userName,
            role: userRole,
            email: userEmail.isEmpty ? nil : userEmail,
            isCurrentUser: true
        )
        member.parentProfile = profile
        modelContext.insert(member)

        let account = ExpenseAccount()
        account.familyMember = member
        member.expenseAccount = account
        modelContext.insert(account)

        RegionalTemplateSeeder.seedDefaults(
            for: profile,
            region: selectedRegion,
            modelContext: modelContext
        )

        if connectHealth {
            asyncRun { @MainActor in _ = await healthKit.requestAuthorization() }
        }

        // Request notification permission and seed reminders after setup
        asyncRun { @MainActor in
            _ = await NotificationManager.requestPermission()
            NotificationManager.resync(context: modelContext)
        }

        try? modelContext.save()
        appMode = "real"
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, Document.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
