//
//  HealthMetricSnapshot.swift
//  CareCircle
//
//  Transient value types for HealthKit query results.
//  Not persisted — queried live from HealthKit each time.
//

import Foundation
import SwiftUI

enum HealthMetricType: String, CaseIterable, Identifiable {
    case heartRate = "Heart Rate"
    case restingHeartRate = "Resting HR"
    case bloodOxygen = "Blood Oxygen"
    case steps = "Steps"
    case bloodPressureSystolic = "BP Systolic"
    case bloodPressureDiastolic = "BP Diastolic"
    case heartRateVariability = "HRV"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .heartRate, .restingHeartRate: return "BPM"
        case .bloodOxygen: return "%"
        case .steps: return "steps"
        case .bloodPressureSystolic, .bloodPressureDiastolic: return "mmHg"
        case .heartRateVariability: return "ms"
        }
    }

    var icon: String {
        switch self {
        case .heartRate, .restingHeartRate: return "heart.fill"
        case .bloodOxygen: return "lungs.fill"
        case .steps: return "figure.walk"
        case .bloodPressureSystolic, .bloodPressureDiastolic: return "waveform.path.ecg"
        case .heartRateVariability: return "waveform.path.ecg.rectangle"
        }
    }

    var color: Color {
        switch self {
        case .heartRate, .restingHeartRate: return .red
        case .bloodOxygen: return .blue
        case .steps: return .green
        case .bloodPressureSystolic, .bloodPressureDiastolic: return .purple
        case .heartRateVariability: return .orange
        }
    }
}

struct HealthMetricSnapshot: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let value: Double
    let timestamp: Date

    var formattedValue: String {
        switch type {
        case .steps:
            return "\(Int(value))"
        case .bloodOxygen:
            return String(format: "%.0f%%", value * 100)
        case .heartRateVariability:
            return String(format: "%.0f", value)
        default:
            return String(format: "%.0f", value)
        }
    }
}
