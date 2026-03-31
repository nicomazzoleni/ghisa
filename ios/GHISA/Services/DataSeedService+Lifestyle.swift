import Foundation
import SwiftData

// MARK: - Lifestyle Data Seeder

extension DataSeedService {
    // MARK: - Public API

    func hasSeededLifestyleData() throws -> Bool {
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.sleepHours != nil
            }
        )
        return try modelContext.fetch(descriptor).count >= 30
    }

    func clearLifestyleData() throws {
        let descriptor = FetchDescriptor<DailyLog>()
        let logs = try modelContext.fetch(descriptor)
        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()
    }

    @MainActor
    func seedLifestyleData() async throws -> Int {
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try modelContext.fetch(userDescriptor).first else {
            throw AppError.validation(message: "No user found. Run initial seed first.")
        }

        let workoutInfo = try loadWorkoutInfo()

        let calendar = Calendar.current
        let today = Date()
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) else { return 0 }

        let existingDescriptor = FetchDescriptor<DailyLog>()
        let existingLogs = try modelContext.fetch(existingDescriptor)
        let existingDates = Set(existingLogs.map { calendar.startOfDay(for: $0.date) })

        var logCount = 0
        var currentDate = calendar.startOfDay(for: oneYearAgo)
        var rng = SeededRandomGenerator(seed: 42)

        while currentDate <= today {
            if !existingDates.contains(currentDate) {
                let log = DailyLog(user: user, date: currentDate)
                populateDailyLog(log, date: currentDate, workoutInfo: workoutInfo, rng: &rng)
                modelContext.insert(log)
                logCount += 1
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next

            if logCount % 30 == 0 { await Task.yield() }
        }

        try modelContext.save()
        return logCount
    }

    /// Populate all fields on a daily log entry with realistic seed data.
    private func populateDailyLog(
        _ log: DailyLog,
        date: Date,
        workoutInfo: WorkoutInfo,
        rng: inout SeededRandomGenerator
    ) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        let tomorrowWeight = workoutWeightForDate(
            calendar.date(byAdding: .day, value: 1, to: date) ?? date,
            workoutInfo: workoutInfo
        )
        let sleepBoost = computeSleepBoost(tomorrowWeight: tomorrowWeight, workoutInfo: workoutInfo)

        // --- Sleep ---
        let baseSleep = 7.25 + seasonalModifier(dayOfYear: dayOfYear, amplitude: 0.3)
        let weekendBoost = isWeekend ? 0.4 : 0.0
        let noise = nextGaussian(rng: &rng) * 0.8
        let sleepHours = clamp(baseSleep + weekendBoost + sleepBoost + noise, min: 4.5, max: 10.0)
        log.sleepHours = Float(sleepHours)

        let totalSleepMinutes = Int(sleepHours * 60)
        let deepPct = clamp(0.20 + nextGaussian(rng: &rng) * 0.04, min: 0.10, max: 0.30)
        let corePct = clamp(0.55 + nextGaussian(rng: &rng) * 0.05, min: 0.40, max: 0.65)
        log.sleepDeepMinutes = Int(Double(totalSleepMinutes) * deepPct)
        log.sleepCoreMinutes = Int(Double(totalSleepMinutes) * corePct)
        log.sleepRemMinutes = max(
            totalSleepMinutes - (log.sleepDeepMinutes ?? 0) - (log.sleepCoreMinutes ?? 0),
            0
        )

        // --- Steps ---
        let isTrainingDay = workoutInfo.trainingDates.contains(date)
        let baseSteps: Double = isWeekend ? 6000 : 7500
        let stepsNoise = nextGaussian(rng: &rng) * 2500
        let steps = clamp(baseSteps + stepsNoise, min: 1500, max: 18000)
        log.steps = Int(steps)

        // --- Resting Heart Rate ---
        let baseRHR = 61.0 + seasonalModifier(dayOfYear: dayOfYear, amplitude: 2.0)
        let rhrNoise = nextGaussian(rng: &rng) * 2.5
        log.restingHeartRate = Int(clamp(baseRHR + rhrNoise, min: 48, max: 78))

        // --- HRV (inversely correlated with RHR) ---
        let baseHRV = 48.0 - seasonalModifier(dayOfYear: dayOfYear, amplitude: 4.0)
        let hrvNoise = nextGaussian(rng: &rng) * 8.0
        let hrvSleepBoost = (sleepHours - 7.0) * 2.0
        log.hrv = Float(clamp(baseHRV + hrvNoise + hrvSleepBoost, min: 15, max: 90))

        // --- Active Energy ---
        let baseEnergy: Double = isTrainingDay ? 650 : 400
        let energyNoise = nextGaussian(rng: &rng) * 120
        log.activeEnergyKcal = Float(clamp(baseEnergy + energyNoise, min: 100, max: 1200))

        // --- Walking Distance ---
        log.walkingDistanceKm = Float(Double(log.steps ?? 0) / 1300.0)
    }

    // MARK: - Workout Info for Correlation Injection

    private struct WorkoutInfo {
        let trainingDates: Set<Date>
        let weightByDate: [Date: Float] // average weight lifted that day
        let medianWeight: Float
    }

    private func loadWorkoutInfo() throws -> WorkoutInfo {
        let calendar = Calendar.current
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.status == "completed"
            }
        )
        let workouts = try modelContext.fetch(descriptor)

        var trainingDates = Set<Date>()
        var weightByDate: [Date: Float] = [:]

        for workout in workouts {
            let date = calendar.startOfDay(for: workout.date)
            trainingDates.insert(date)

            var totalWeight: Float = 0
            var setCount = 0
            for we in workout.workoutExercises {
                for set in we.sets {
                    for value in set.values where value.fieldDefinition.systemKey == "weight" {
                        if let weight = value.valueNumber {
                            totalWeight += weight
                            setCount += 1
                        }
                    }
                }
            }
            if setCount > 0 {
                weightByDate[date] = totalWeight / Float(setCount)
            }
        }

        let allWeights = Array(weightByDate.values).sorted()
        let median = allWeights.isEmpty ? Float(0) : allWeights[allWeights.count / 2]

        return WorkoutInfo(trainingDates: trainingDates, weightByDate: weightByDate, medianWeight: median)
    }

    private func workoutWeightForDate(_ date: Date, workoutInfo: WorkoutInfo) -> Float? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return workoutInfo.weightByDate[startOfDay]
    }

    /// Inject positive sleep-performance correlation: better sleep before heavier workouts.
    private func computeSleepBoost(tomorrowWeight: Float?, workoutInfo: WorkoutInfo) -> Double {
        guard let weight = tomorrowWeight, workoutInfo.medianWeight > 0 else { return 0 }
        // If tomorrow's weight is above median, boost sleep by up to 0.8h
        let deviation = (weight - workoutInfo.medianWeight) / workoutInfo.medianWeight
        return Double(clamp(Float(deviation) * 2.0, min: -0.5, max: 0.8))
    }

    // MARK: - Utility

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }

    /// Seasonal modifier using a sine wave (peaks in summer ~day 180).
    private func seasonalModifier(dayOfYear: Int, amplitude: Double) -> Double {
        let phase = Double(dayOfYear) / 365.0 * 2.0 * .pi
        return sin(phase) * amplitude
    }

    /// Box-Muller transform for Gaussian noise.
    private func nextGaussian(rng: inout SeededRandomGenerator) -> Double {
        let u1 = Double.random(in: 0.001 ... 1.0, using: &rng)
        let u2 = Double.random(in: 0.0 ... 1.0, using: &rng)
        return sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    }
}

// MARK: - Seeded Random Number Generator

/// Simple linear congruential generator for reproducible seed data.
private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
