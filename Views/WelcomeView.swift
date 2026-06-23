//
//  WelcomeView.swift
//  CareCircle
//
//  Launch screen with two paths: Demo or Sign Up.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("appMode") private var appMode: String = "none"
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            CareCircleScreenWash(isHero: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo & tagline
                VStack(spacing: 16) {
                    CareCircleMark(size: 82)
                        .shadow(color: .careTint.opacity(0.24), radius: 18, y: 8)

                    Text("CareCircle")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.careInk)

                    Text("One place to coordinate care\nfor the people who matter most")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Feature highlights
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(
                        icon: "calendar.badge.clock",
                        title: "Appointments & Checklists",
                        subtitle: "Never miss a visit or forget a document"
                    )
                    featureRow(
                        icon: "person.3.fill",
                        title: "Family Coordination",
                        subtitle: "Assign tasks and track who owns what"
                    )
                    featureRow(
                        icon: "heart.text.square.fill",
                        title: "Health Monitoring",
                        subtitle: "Apple Watch vitals shared with trusted family"
                    )
                    featureRow(
                        icon: "sparkles",
                        title: "AI-Powered Summaries",
                        subtitle: "On-device intelligence, private by design"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                VStack(spacing: 14) {
                    Button {
                        SampleDataGenerator.clearAllData(modelContext: modelContext)
                        appMode = "signup" // move into onboarding flow explicitly
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.careTint)
                    .controlSize(.large)

                    Button {
                        SampleDataGenerator.generateSampleData(modelContext: modelContext)
                        appMode = "demo"
                    } label: {
                        Text("Try the Demo")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.careTint)
                    .controlSize(.large)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.careTint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .modelContainer(for: [
            ParentProfile.self, Appointment.self,
            Task.self, Document.self,
            FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
