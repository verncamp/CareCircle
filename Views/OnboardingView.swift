//
//  OnboardingView.swift
//  CareCircle
//
//  Step-by-step profile setup for real (non-demo) users.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"

    @State private var step = 0
    @State private var healthKit = HealthKitManager()

    // Parent fields
    @State private var parentName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -75, to: Date()) ?? Date()
    @State private var bloodType = ""
    @State private var allergies = ""
    @State private var primaryPhysician = ""
    @State private var statusMessage = "Stable today"

    // User fields
    @State private var userName = ""
    @State private var userRole: FamilyRole = .medicalAdmin

    // Optional
    @State private var connectHealth = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.1),
                    Color.mint.opacity(0.05),
                    Color(red: 0.98, green: 0.88, blue: 0.82).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.teal : Color.teal.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Content
                TabView(selection: $step) {
                    parentStep.tag(0)
                    userStep.tag(1)
                    finishStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                // Navigation
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
                        .disabled(step == 0 && parentName.isEmpty)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Step 1: Parent Info

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
                        .font(.body)

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)

                    TextField("Blood type (optional)", text: $bloodType)
                        .textFieldStyle(.roundedBorder)

                    TextField("Known allergies (optional)", text: $allergies)
                        .textFieldStyle(.roundedBorder)

                    TextField("Primary physician (optional)", text: $primaryPhysician)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 2: Your Info

    private var userStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tell us about you")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("You'll be the first member of the care circle.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    TextField("Your name", text: $userName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Your role", selection: $userRole) {
                        ForEach(FamilyRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle(isOn: $connectHealth) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect Apple Health")
                                .font(.subheadline)
                            Text("Share vitals with trusted family members")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.teal)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 3: Confirm & Create

    private var finishStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.teal)

                    Text("You're all set!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("We'll create a care circle for \(parentName.isEmpty ? "your parent" : parentName) with you as the first member.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Summary card
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Summary")

                    if !parentName.isEmpty {
                        summaryRow(label: "Care recipient", value: parentName)
                    }
                    if !userName.isEmpty {
                        summaryRow(label: "You", value: "\(userName) (\(userRole.rawValue))")
                    }
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
                .tint(.teal)
                .controlSize(.large)
                .disabled(parentName.isEmpty)
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
            statusMessage: statusMessage,
            dateOfBirth: dateOfBirth,
            bloodType: bloodType.isEmpty ? nil : bloodType,
            allergies: allergies.isEmpty ? nil : allergies,
            primaryPhysician: primaryPhysician.isEmpty ? nil : primaryPhysician,
            healthKitEnabled: connectHealth
        )
        modelContext.insert(profile)

        // Create the user as first family member
        if !userName.isEmpty {
            let member = FamilyMember(
                name: userName,
                role: userRole,
                isCurrentUser: true
            )
            member.parentProfile = profile
            modelContext.insert(member)

            let account = ExpenseAccount()
            account.familyMember = member
            member.expenseAccount = account
            modelContext.insert(account)
        }

        // Request HealthKit if opted in
        if connectHealth {
            asyncRun {
                _ = await healthKit.requestAuthorization()
            }
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
