//
//  OnboardingView.swift
//  CareCircle
//
//  Step-by-step setup: Sign in → Parent info → Confirm.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appMode") private var appMode: String = "none"

    @State private var step = 0
    @State private var healthKit = HealthKitManager()

    // Account (Step 1)
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var signedInWithApple = false

    // Parent (Step 2)
    @State private var parentName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -75, to: Date()) ?? Date()
    @State private var bloodType = ""
    @State private var allergies = ""
    @State private var primaryPhysician = ""

    // Role & options (Step 2)
    @State private var userRole: FamilyRole = .medicalAdmin
    @State private var connectHealth = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
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

                // Steps
                TabView(selection: $step) {
                    accountStep.tag(0)
                    parentStep.tag(1)
                    confirmStep.tag(2)
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
                        .disabled(!canAdvance)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return !userName.isEmpty
        case 1: return !parentName.isEmpty
        default: return true
        }
    }

    // MARK: - Step 1: Your Account

    private var accountStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Create your account")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Sign in to save your care circle across devices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // Sign in with Apple
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 24)

                // Divider
                HStack {
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                    Text("or sign up with email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                }
                .padding(.horizontal, 24)

                // Manual entry
                VStack(spacing: 16) {
                    TextField("Full name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()

                    TextField("Email address", text: $userEmail)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 24)

                if signedInWithApple {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Signed in with Apple")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                if let fullName = credential.fullName {
                    let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
                    if !parts.isEmpty {
                        userName = parts.joined(separator: " ")
                    }
                }
                if let email = credential.email {
                    userEmail = email
                }
                signedInWithApple = true
                // Auto-advance to next step
                withAnimation { step = 1 }
            }
        case .failure:
            break
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

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
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

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Summary")
                    summaryRow(label: "You", value: userName)
                    if !userEmail.isEmpty {
                        summaryRow(label: "Email", value: userEmail)
                    }
                    summaryRow(label: "Role", value: userRole.rawValue)
                    summaryRow(label: "Care recipient", value: parentName)
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
