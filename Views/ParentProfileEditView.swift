//
//  ParentProfileEditView.swift
//  CareCircle
//

import SwiftUI
import PhotosUI

struct ParentProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var profile: ParentProfile
    @State private var healthKit = HealthKitManager()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var newMedName = ""
    @State private var newMedDosage = ""
    @State private var newMedFrequency = "Once daily"
    @State private var newCondition = ""

    let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed", "Weekly"]

    var body: some View {
        NavigationStack {
            Form {
                // Photo & Basic Info
                Section("Profile") {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let photoData = profile.photoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                AvatarView(name: profile.name, size: 80, gradient: [.teal, .mint])
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.teal)
                                            .background(.white, in: Circle())
                                    }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    TextField("Name", text: $profile.name)
                    TextField("Status", text: $profile.statusMessage)
                    DatePicker("Date of Birth", selection: Binding(
                        get: { profile.dateOfBirth ?? Date() },
                        set: { profile.dateOfBirth = $0 }
                    ), displayedComponents: .date)
                }

                // Medical
                Section("Medical") {
                    TextField("Blood Type", text: Binding(
                        get: { profile.bloodType ?? "" },
                        set: { profile.bloodType = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Allergies", text: Binding(
                        get: { profile.allergies ?? "" },
                        set: { profile.allergies = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Primary Physician", text: Binding(
                        get: { profile.primaryPhysician ?? "" },
                        set: { profile.primaryPhysician = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Insurance Provider", text: Binding(
                        get: { profile.insuranceProvider ?? "" },
                        set: { profile.insuranceProvider = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Policy Number", text: Binding(
                        get: { profile.insuranceNumber ?? "" },
                        set: { profile.insuranceNumber = $0.isEmpty ? nil : $0 }
                    ))
                }

                // Medications
                Section("Medications") {
                    ForEach(profile.medications) { med in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(med.dosage) · \(med.frequency)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indices in
                        profile.medications.remove(atOffsets: indices)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Medication name", text: $newMedName)
                        TextField("Dosage (e.g. 10mg)", text: $newMedDosage)
                        Picker("Frequency", selection: $newMedFrequency) {
                            ForEach(frequencies, id: \.self) { Text($0) }
                        }
                        Button("Add Medication") {
                            guard !newMedName.isEmpty else { return }
                            profile.medications.append(Medication(
                                name: newMedName,
                                dosage: newMedDosage,
                                frequency: newMedFrequency
                            ))
                            newMedName = ""
                            newMedDosage = ""
                        }
                        .disabled(newMedName.isEmpty)
                    }
                }

                // Conditions
                Section("Conditions") {
                    ForEach(profile.conditions, id: \.self) { condition in
                        Text(condition)
                    }
                    .onDelete { indices in
                        profile.conditions.remove(atOffsets: indices)
                    }

                    HStack {
                        TextField("Add condition", text: $newCondition)
                        Button("Add") {
                            guard !newCondition.isEmpty else { return }
                            profile.conditions.append(newCondition)
                            newCondition = ""
                        }
                        .disabled(newCondition.isEmpty)
                    }
                }

                // Emergency & Pharmacy
                Section("Emergency Contacts") {
                    TextField("Emergency Contact Name", text: Binding(
                        get: { profile.emergencyContactName ?? "" },
                        set: { profile.emergencyContactName = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Emergency Contact Phone", text: Binding(
                        get: { profile.emergencyContactPhone ?? "" },
                        set: { profile.emergencyContactPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                    TextField("Pharmacy Name", text: Binding(
                        get: { profile.pharmacyName ?? "" },
                        set: { profile.pharmacyName = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Pharmacy Phone", text: Binding(
                        get: { profile.pharmacyPhone ?? "" },
                        set: { profile.pharmacyPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                }

                // Health
                Section {
                    Toggle("Connect Apple Health", isOn: $profile.healthKitEnabled)
                        .onChange(of: profile.healthKitEnabled) { _, enabled in
                            if enabled {
                                asyncRun {
                                    let authorized = await healthKit.requestAuthorization()
                                    if !authorized {
                                        profile.healthKitEnabled = false
                                    }
                                }
                            }
                        }
                } header: {
                    Text("Apple Health")
                } footer: {
                    Text("Read heart rate, blood oxygen, steps, and blood pressure from this device's Health app. To share data with family members on other devices, enable Health Sharing in Settings > Health > Sharing.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        profile.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                asyncRun {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        profile.photoData = data
                    }
                }
            }
        }
    }
}

#Preview {
    ParentProfileEditView(profile: ParentProfile(name: "Mom Alvarez"))
        .modelContainer(for: [
            ParentProfile.self, Appointment.self, Task.self,
            Document.self, FamilyMember.self, Expense.self,
            ExpenseAccount.self, UpdateFeedItem.self
        ], inMemory: true)
}
