import Foundation
import HealthKit
import SwiftData

struct HealthKitDailyData {
    var sleepHours: Float?
    var sleepDeepMinutes: Int?
    var sleepCoreMinutes: Int?
    var sleepRemMinutes: Int?
    var steps: Int?
    var restingHeartRate: Int?
    var hrv: Float?
    var activeEnergyKcal: Float?
    var walkingDistanceKm: Float?
}

@Observable
final class HealthKitService: @unchecked Sendable {
    private let healthStore = HKHealthStore()

    private static let authRequestedKey = "healthKit_authRequested"

    var isAuthorized: Bool {
        get { UserDefaults.standard.bool(forKey: Self.authRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.authRequestedKey) }
    }

    /// Types we want to read from HealthKit
    private var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
        ]
        return Set(types.compactMap(\.self))
    }

    /// Request HealthKit authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AppError.healthKit(underlying: NSError(
                domain: "HealthKit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Health data not available"]
            ))
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    /// Fetch daily HealthKit data for a specific date
    func fetchDailyData(for date: Date) async throws -> HealthKitDailyData {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return HealthKitDailyData()
        }

        let store = healthStore
        async let activityData = Self.fetchActivityMetrics(store: store, start: startOfDay, end: endOfDay)
        async let vitalData = Self.fetchVitalMetrics(store: store, start: startOfDay, end: endOfDay)
        async let sleepData = Self.fetchSleepData(store: store, for: date)

        let (activity, vitals, sleep) = try await (activityData, vitalData, sleepData)

        return HealthKitDailyData(
            sleepHours: sleep.totalHours,
            sleepDeepMinutes: sleep.deepMinutes,
            sleepCoreMinutes: sleep.coreMinutes,
            sleepRemMinutes: sleep.remMinutes,
            steps: activity.steps.map { Int($0) },
            restingHeartRate: vitals.restingHR.map { Int($0) },
            hrv: vitals.hrv.map { Float($0) },
            activeEnergyKcal: activity.activeEnergy.map { Float($0) },
            walkingDistanceKm: activity.distance.map { Float($0) }
        )
    }

    private struct ActivityMetrics {
        var steps: Double?
        var activeEnergy: Double?
        var distance: Double?
    }

    private struct VitalMetrics {
        var restingHR: Double?
        var hrv: Double?
    }

    private static func fetchActivityMetrics(
        store: HKHealthStore, start: Date, end: Date
    ) async throws -> ActivityMetrics {
        async let steps = fetchCumulativeSum(
            store: store,
            typeIdentifier: .stepCount,
            start: start,
            end: end,
            unit: HKUnit.count()
        )
        async let energy = fetchCumulativeSum(
            store: store,
            typeIdentifier: .activeEnergyBurned,
            start: start,
            end: end,
            unit: HKUnit.kilocalorie()
        )
        async let dist = fetchCumulativeSum(
            store: store,
            typeIdentifier: .distanceWalkingRunning,
            start: start,
            end: end,
            unit: HKUnit.meterUnit(with: .kilo)
        )
        let (stepsVal, energyVal, distVal) = try await (steps, energy, dist)
        return ActivityMetrics(steps: stepsVal, activeEnergy: energyVal, distance: distVal)
    }

    private static func fetchVitalMetrics(
        store: HKHealthStore, start: Date, end: Date
    ) async throws -> VitalMetrics {
        async let rhr = fetchDiscreteAverage(
            store: store,
            typeIdentifier: .restingHeartRate,
            start: start,
            end: end,
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        async let hrv = fetchDiscreteAverage(
            store: store,
            typeIdentifier: .heartRateVariabilitySDNN,
            start: start,
            end: end,
            unit: HKUnit.secondUnit(with: .milli)
        )
        let (rhrVal, hrvVal) = try await (rhr, hrv)
        return VitalMetrics(restingHR: rhrVal, hrv: hrvVal)
    }

    /// Perform 90-day historical import into SwiftData
    func performHistoricalImport(modelContext: ModelContext, user: User) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar
            .date(byAdding: .day, value: -AppConfig.HealthKit.historicalImportDays, to: today)
        else {
            return
        }

        for dayOffset in 0 ..< AppConfig.HealthKit.historicalImportDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            let data = try await fetchDailyData(for: date)

            // Skip days with no data at all
            guard data.hasAnyData else { continue }

            let dailyLog = Self.fetchOrCreateDailyLog(for: date, user: user, modelContext: modelContext)
            Self.applyHealthKitData(data, to: dailyLog)

            // Save periodically every 10 days
            if dayOffset % 10 == 9 {
                try modelContext.save()
            }
        }

        try modelContext.save()
    }

    // MARK: - Private Static Helpers

    private static func fetchCumulativeSum(
        store: HKHealthStore,
        typeIdentifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: AppError.healthKit(underlying: error))
                    return
                }
                let value = result?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private static func fetchDiscreteAverage(
        store: HKHealthStore,
        typeIdentifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: AppError.healthKit(underlying: error))
                    return
                }
                let value = result?.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private struct SleepResult {
        var totalHours: Float?
        var deepMinutes: Int?
        var coreMinutes: Int?
        var remMinutes: Int?
    }

    private static func fetchSleepData(store: HKHealthStore, for date: Date) async throws -> SleepResult {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return SleepResult()
        }

        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        // Sleep spans midnight — query from 6PM prior day to noon target day
        guard let queryStart = calendar.date(byAdding: .hour, value: -6, to: targetDay),
              let queryEnd = calendar.date(byAdding: .hour, value: 12, to: targetDay)
        else {
            return SleepResult()
        }

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: AppError.healthKit(underlying: error))
                    return
                }
                let categorySamples = (results as? [HKCategorySample]) ?? []
                continuation.resume(returning: categorySamples)
            }
            store.execute(query)
        }

        return sleepResultFromSamples(samples)
    }

    private static func sleepResultFromSamples(_ samples: [HKCategorySample]) -> SleepResult {
        var deepSeconds: TimeInterval = 0
        var coreSeconds: TimeInterval = 0
        var remSeconds: TimeInterval = 0
        var unspecifiedSeconds: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    coreSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    unspecifiedSeconds += duration
                default:
                    break
            }
        }

        let totalSeconds = deepSeconds + coreSeconds + remSeconds + unspecifiedSeconds
        guard totalSeconds > 0 else { return SleepResult() }

        return SleepResult(
            totalHours: Float(totalSeconds / 3600.0),
            deepMinutes: Int(deepSeconds / 60.0),
            coreMinutes: Int(coreSeconds / 60.0),
            remMinutes: Int(remSeconds / 60.0)
        )
    }

    private static func fetchOrCreateDailyLog(for date: Date, user: User, modelContext: ModelContext) -> DailyLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let userId = user.id
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.user.id == userId && log.date >= startOfDay && log.date < nextDay
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newLog = DailyLog(user: user, date: startOfDay)
        modelContext.insert(newLog)
        return newLog
    }

    private static func applyHealthKitData(_ data: HealthKitDailyData, to dailyLog: DailyLog) {
        dailyLog.sleepHours = data.sleepHours ?? dailyLog.sleepHours
        dailyLog.sleepDeepMinutes = data.sleepDeepMinutes ?? dailyLog.sleepDeepMinutes
        dailyLog.sleepCoreMinutes = data.sleepCoreMinutes ?? dailyLog.sleepCoreMinutes
        dailyLog.sleepRemMinutes = data.sleepRemMinutes ?? dailyLog.sleepRemMinutes
        dailyLog.steps = data.steps ?? dailyLog.steps
        dailyLog.restingHeartRate = data.restingHeartRate ?? dailyLog.restingHeartRate
        dailyLog.hrv = data.hrv ?? dailyLog.hrv
        dailyLog.activeEnergyKcal = data.activeEnergyKcal ?? dailyLog.activeEnergyKcal
        dailyLog.walkingDistanceKm = data.walkingDistanceKm ?? dailyLog.walkingDistanceKm
        dailyLog.updatedAt = Date()
    }
}

extension HealthKitDailyData {
    var hasAnyData: Bool {
        sleepHours != nil || steps != nil || restingHeartRate != nil ||
            hrv != nil || activeEnergyKcal != nil || walkingDistanceKm != nil
    }
}
