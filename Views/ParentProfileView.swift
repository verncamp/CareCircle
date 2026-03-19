//
//  ParentProfileView.swift
//  CareCircle
//

import SwiftUI
import SwiftData
import Charts

struct ParentProfileView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: ParentProfile

    @State private var healthKit = HealthKitManager()
    @State private var showingEdit = false
    @State private var showingShareSheet = false
    @State private var emergencyPDFData: Data?

    var age: Int? {
        guard let dob = profile.dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                quickInfoBadges
                medicalInfoCard
                medicationsCard
                conditionsCard

                if profile.healthKitEnabled {
                    healthMetricsCard
                }

                emergencyCard
                emergencyPacketCard
                familyCircleCard
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .adaptiveWidth()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingEdit) {
            ParentProfileEditView(profile: profile)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = emergencyPDFData {
                ShareSheet(items: [data])
            }
        }
        .task {
            if profile.healthKitEnabled && healthKit.isAvailable {
                _ = await healthKit.requestAuthorization()
                await healthKit.fetchLatestMetrics()
                await healthKit.fetchHeartRateHistory()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            if let photoData = profile.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            } else {
                AvatarView(name: profile.name, size: 96, gradient: [.teal, .mint])
            }

            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.title)
                    .fontWeight(.bold)

                if let age {
                    Text("Age \(age)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(profile.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Quick Info Badges

    private var quickInfoBadges: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let bloodType = profile.bloodType, !bloodType.isEmpty {
                    badge(icon: "drop.fill", label: bloodType, color: .red)
                }
                if let allergies = profile.allergies, !allergies.isEmpty {
                    badge(icon: "exclamationmark.triangle.fill", label: allergies, color: .orange)
                }
                if let dob = profile.dateOfBirth {
                    badge(icon: "birthday.cake.fill", label: dob.formatted(date: .abbreviated, time: .omitted), color: .purple)
                }
            }
        }
    }

    private func badge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Medical Info

    private var medicalInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Medical Info")

            infoRow(icon: "stethoscope", label: "Physician", value: profile.primaryPhysician)
            infoRow(icon: "shield.checkered", label: "Insurance", value: profile.insuranceProvider)
            if let num = profile.insuranceNumber, !num.isEmpty {
                infoRow(icon: "number", label: "Policy #", value: num)
            }
            infoRow(icon: "cross.fill", label: "Pharmacy", value: profile.pharmacyName)
        }
        .glassCard()
    }

    private func infoRow(icon: String, label: String, value: String?) -> some View {
        Group {
            if let value, !value.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundStyle(.teal)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Medications

    private var medicationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Medications")

            if profile.medications.isEmpty {
                Text("No medications listed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profile.medications) { med in
                    HStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(.teal)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(med.dosage) · \(med.frequency)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Conditions

    private var conditionsCard: some View {
        Group {
            if !profile.conditions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Conditions")

                    FlowLayout(spacing: 8) {
                        ForEach(profile.conditions, id: \.self) { condition in
                            Text(condition)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.teal.opacity(0.1), in: Capsule())
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    // MARK: - Health Metrics

    private var healthMetricsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Health Metrics")
                if healthKit.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if healthKit.metrics.isEmpty && !healthKit.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No health data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Health data is read from this device's Health app.\nTo share with family, enable Health Sharing in Settings > Health > Sharing.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(healthKit.metrics) { metric in
                        metricTile(metric)
                    }
                }

                // Heart rate mini chart
                if !healthKit.heartRateHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Heart Rate — 7 Days")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Chart(healthKit.heartRateHistory) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("BPM", point.value)
                            )
                            .foregroundStyle(.red.gradient)
                            .interpolationMethod(.catmullRom)
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                        .frame(height: 60)
                    }
                }
            }

            if let updated = healthKit.lastUpdated {
                HStack {
                    Spacer()
                    Text("Updated \(updated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                asyncRun { @MainActor in
                    await healthKit.fetchLatestMetrics()
                    await healthKit.fetchHeartRateHistory()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .disabled(healthKit.isLoading)
        }
        .glassCard()
    }

    private func metricTile(_ metric: HealthMetricSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: metric.type.icon)
                    .foregroundStyle(metric.type.color)
                Text(metric.type.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(metric.formattedValue)
                .font(.title2)
                .fontWeight(.bold)

            Text(metric.type.unit)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Emergency

    private var emergencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Emergency Contacts")

            if let name = profile.emergencyContactName, !name.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "phone.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let phone = profile.emergencyContactPhone {
                            Text(phone)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            if let pharmacy = profile.pharmacyName, !pharmacy.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "cross.circle.fill")
                        .foregroundStyle(.teal)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(pharmacy)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let phone = profile.pharmacyPhone {
                            Text(phone)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            if profile.emergencyContactName == nil && profile.pharmacyName == nil {
                Text("No emergency contacts added yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }

    // MARK: - Emergency Packet

    private var emergencyPacketCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Emergency Packet")

            Text("Generate a printable PDF with all critical care information for emergency responders.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                emergencyPDFData = EmergencyPacketGenerator.generate(for: profile)
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Generate & Share PDF")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .glassCard()
    }

    // MARK: - Family Circle

    private var familyCircleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Care Team")

            if profile.familyMembers.isEmpty {
                Text("No family members yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(profile.familyMembers) { member in
                            VStack(spacing: 6) {
                                AvatarView(name: member.name, size: 44)
                                Text(member.name.split(separator: " ").first.map(String.init) ?? member.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Flow Layout for condition tags

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ParentProfileView(profile: ParentProfile(
            name: "Mom Alvarez",
            bloodType: "O+",
            allergies: "Penicillin",
            primaryPhysician: "Dr. Sarah Chen",
            medications: [
                Medication(name: "Lisinopril", dosage: "10mg", frequency: "Once daily"),
                Medication(name: "Metformin", dosage: "500mg", frequency: "Twice daily")
            ],
            conditions: ["Hypertension", "Type 2 Diabetes"]
        ))
    }
    .modelContainer(for: [
        ParentProfile.self, Appointment.self, Task.self,
        Document.self, FamilyMember.self, Expense.self,
        ExpenseAccount.self, UpdateFeedItem.self
    ], inMemory: true)
}
