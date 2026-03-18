//
//  HealthKitManager.swift
//  CareCircle
//
//  Reads health data from this device's HealthKit store.
//  For family sharing, the parent enables Health Sharing in
//  Settings > Health > Sharing, and the family member's device
//  will show the shared data through their own HealthKit store.
//

import Foundation
import HealthKit

@Observable
@MainActor
class HealthKitManager {
    private let store = HKHealthStore()

    var metrics: [HealthMetricSnapshot] = []
    var heartRateHistory: [HealthMetricSnapshot] = []
    var isLoading = false
    var lastUpdated: Date?
    var errorMessage: String?

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // Types we want to read
    private var readTypes: Set<HKObjectType> {
        let quantities: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .restingHeartRate,
            .oxygenSaturation,
            .stepCount,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .heartRateVariabilitySDNN
        ]
        return Set(quantities.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Fetch All Latest

    func fetchLatestMetrics() async {
        guard isAvailable else { return }

        isLoading = true
        defer { isLoading = false }

        var results: [HealthMetricSnapshot] = []

        async let hr = fetchLatest(.heartRate, unit: HKUnit(from: "count/min"), type: .heartRate)
        async let rhr = fetchLatest(.restingHeartRate, unit: HKUnit(from: "count/min"), type: .restingHeartRate)
        async let o2 = fetchLatest(.oxygenSaturation, unit: HKUnit.percent(), type: .bloodOxygen)
        async let steps = fetchTodaySum(.stepCount, unit: HKUnit.count(), type: .steps)
        async let bpSys = fetchLatest(.bloodPressureSystolic, unit: HKUnit.millimeterOfMercury(), type: .bloodPressureSystolic)
        async let bpDia = fetchLatest(.bloodPressureDiastolic, unit: HKUnit.millimeterOfMercury(), type: .bloodPressureDiastolic)
        async let hrv = fetchLatest(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), type: .heartRateVariability)

        let all = await [hr, rhr, o2, steps, bpSys, bpDia, hrv]
        results = all.compactMap { $0 }

        metrics = results
        lastUpdated = Date()
    }

    // MARK: - Heart Rate History (7 days)

    func fetchHeartRateHistory() async {
        guard isAvailable else { return }
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        do {
            let samples = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKQuantitySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: 200,
                    sortDescriptors: [sort]
                ) { _, results, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: (results as? [HKQuantitySample]) ?? [])
                    }
                }
                store.execute(query)
            }

            heartRateHistory = samples.map { sample in
                HealthMetricSnapshot(
                    type: .heartRate,
                    value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                    timestamp: sample.startDate
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private Helpers

    private func fetchLatest(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        type: HealthMetricType
    ) async -> HealthMetricSnapshot? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        do {
            let sample = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<HKQuantitySample?, Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sort]
                ) { _, results, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: results?.first as? HKQuantitySample)
                    }
                }
                store.execute(query)
            }

            guard let sample else { return nil }
            return HealthMetricSnapshot(
                type: type,
                value: sample.quantity.doubleValue(for: unit),
                timestamp: sample.startDate
            )
        } catch {
            return nil
        }
    }

    private func fetchTodaySum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        type: HealthMetricType
    ) async -> HealthMetricSnapshot? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        do {
            let sum = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, stats, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                        cont.resume(returning: value)
                    }
                }
                store.execute(query)
            }

            return HealthMetricSnapshot(type: type, value: sum, timestamp: Date())
        } catch {
            return nil
        }
    }
}
