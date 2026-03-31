// swiftlint:disable file_length
import Foundation
import SwiftData

// MARK: - Paired Data Types

struct PairedData {
    let targetValues: [Double]
    let factorValues: [Double]
    let dates: [Date]
    let sampleSize: Int
    let dataCompleteness: Double
}

struct GroupedData {
    let targetValuesByGroup: [String: [Double]]
    let sampleSize: Int
    let dataCompleteness: Double
}

// MARK: - Data Extraction Service

@Observable
// swiftlint:disable:next type_body_length
final class DataExtractionService {
    private let modelContext: ModelContext

    // Batch caches — populated once per recomputation cycle
    private var workoutCache: [Date: [Workout]]?
    private var mealEntryCache: [Date: [MealEntry]]?
    private var dailyLogCache: [Date: DailyLog]?
    private var nutrientDefinitionsCache: [NutrientDefinition]?
    private var nutrientApiKeyToId: [String: UUID]?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Clear internal caches. Call after a recomputation cycle completes.
    func clearCaches() {
        workoutCache = nil
        mealEntryCache = nil
        dailyLogCache = nil
        nutrientDefinitionsCache = nil
        nutrientApiKeyToId = nil
    }

    // MARK: - Time Series Extraction

    /// Extract a single variable's time series for a date range.
    func extractTimeSeries(
        variable: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, value: Double)] {
        switch variable.category {
            case .training:
                try extractTrainingVariable(variable, userId: userId, dateRange: dateRange)
            case .nutrition:
                try extractNutritionVariable(variable, userId: userId, dateRange: dateRange)
            case .lifestyle:
                try extractLifestyleVariable(variable, userId: userId, dateRange: dateRange)
            case .derived:
                try extractDerivedVariable(variable, userId: userId, dateRange: dateRange)
        }
    }

    // MARK: - Paired Extraction (Continuous/Ordinal factors)

    /// Pair target and factor values on matching dates, with optional lag.
    /// For lag=k, matches factor[date - k] with target[date].
    func extractPairedData(
        target: CorrelationVariable,
        factor: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>,
        lagDays: Int = 0
    ) throws -> PairedData {
        let calendar = Calendar.current
        let targetSeries = try extractTimeSeries(variable: target, userId: userId, dateRange: dateRange)
        let factorSeries = try extractTimeSeries(variable: factor, userId: userId, dateRange: dateRange)

        // Build lookup for factor by date
        var factorByDate: [Date: Double] = [:]
        for entry in factorSeries {
            factorByDate[calendar.startOfDay(for: entry.date)] = entry.value
        }

        var targetValues: [Double] = []
        var factorValues: [Double] = []
        var dates: [Date] = []

        for entry in targetSeries {
            let targetDate = calendar.startOfDay(for: entry.date)
            guard let factorDate = calendar.date(byAdding: .day, value: -lagDays, to: targetDate) else {
                continue
            }
            let factorDay = calendar.startOfDay(for: factorDate)

            if let factorValue = factorByDate[factorDay] {
                targetValues.append(entry.value)
                factorValues.append(factorValue)
                dates.append(targetDate)
            }
        }

        // Compute data completeness
        let totalDays = max(
            calendar.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 1,
            1
        )
        let completeness = Double(targetValues.count) / Double(totalDays)

        return PairedData(
            targetValues: targetValues,
            factorValues: factorValues,
            dates: dates,
            sampleSize: targetValues.count,
            dataCompleteness: min(completeness, 1.0)
        )
    }

    // MARK: - Grouped Extraction (Binary/Categorical factors)

    /// Extract target values grouped by factor categories, with optional lag.
    func extractGroupedData(
        target: CorrelationVariable,
        factor: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>,
        lagDays: Int = 0
    ) throws -> GroupedData {
        let calendar = Calendar.current
        let targetSeries = try extractTimeSeries(variable: target, userId: userId, dateRange: dateRange)

        // For categorical/binary, extract as string labels
        let factorLabels = try extractLabels(variable: factor, userId: userId, dateRange: dateRange)
        var labelByDate: [Date: String] = [:]
        for entry in factorLabels {
            labelByDate[calendar.startOfDay(for: entry.date)] = entry.label
        }

        var groups: [String: [Double]] = [:]

        for entry in targetSeries {
            let targetDate = calendar.startOfDay(for: entry.date)
            guard let factorDate = calendar.date(byAdding: .day, value: -lagDays, to: targetDate) else {
                continue
            }
            let factorDay = calendar.startOfDay(for: factorDate)

            if let label = labelByDate[factorDay] {
                groups[label, default: []].append(entry.value)
            }
        }

        let totalCount = groups.values.reduce(0) { $0 + $1.count }
        let totalDays = max(
            calendar.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 1,
            1
        )

        return GroupedData(
            targetValuesByGroup: groups,
            sampleSize: totalCount,
            dataCompleteness: min(Double(totalCount) / Double(totalDays), 1.0)
        )
    }

    /// Compute mean of target in HIGH vs LOW buckets (median split of factor).
    func computeBucketMeans(targetValues: [Double], factorValues: [Double]) -> (meanHigh: Double, meanLow: Double)? {
        guard targetValues.count == factorValues.count, !targetValues.isEmpty else { return nil }

        let sortedFactor = factorValues.sorted()
        let median = sortedFactor[sortedFactor.count / 2]

        var highValues: [Double] = []
        var lowValues: [Double] = []

        for i in 0 ..< targetValues.count {
            if factorValues[i] >= median {
                highValues.append(targetValues[i])
            } else {
                lowValues.append(targetValues[i])
            }
        }

        guard !highValues.isEmpty, !lowValues.isEmpty else { return nil }

        let meanHigh = highValues.reduce(0, +) / Double(highValues.count)
        let meanLow = lowValues.reduce(0, +) / Double(lowValues.count)
        return (meanHigh, meanLow)
    }

    // MARK: - Training Variable Extraction

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func extractTrainingVariable(
        _ variable: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, value: Double)] {
        let workouts = try fetchWorkouts(userId: userId, dateRange: dateRange)

        switch variable.id {
            case "session_volume":
                return workouts.compactMap { date, dayWorkouts in
                    let volume = dayWorkouts.reduce(0.0) { total, workout in
                        total + computeSessionVolume(workout)
                    }
                    return volume > 0 ? (date, volume) : nil
                }.sorted { $0.date < $1.date }

            case _ where variable.id.hasPrefix("volume_"):
                guard let muscleGroup = variable.muscleGroup else { return [] }
                return workouts.compactMap { date, dayWorkouts in
                    let volume = dayWorkouts.reduce(0.0) { total, workout in
                        total + computeMuscleGroupVolume(workout, muscleGroup: muscleGroup)
                    }
                    return volume > 0 ? (date, volume) : nil
                }.sorted { $0.date < $1.date }

            case _ where variable.id.hasPrefix("e1rm_"):
                guard let exerciseId = variable.exerciseId else { return [] }
                return workouts.compactMap { date, dayWorkouts -> (Date, Double)? in
                    var bestE1RM = 0.0
                    for workout in dayWorkouts {
                        for we in workout.workoutExercises where we.exercise?.id == exerciseId {
                            for set in we.sets {
                                if let e1rm = computeE1RM(set) {
                                    bestE1RM = max(bestE1RM, e1rm)
                                }
                            }
                        }
                    }
                    return bestE1RM > 0 ? (date, bestE1RM) : nil
                }.sorted { $0.date < $1.date }

            case "sets_to_failure":
                return workouts.compactMap { date, dayWorkouts in
                    let count = dayWorkouts.reduce(0.0) { total, workout in
                        total + Double(countSetsToFailure(workout))
                    }
                    return (date, count)
                }.sorted { $0.date < $1.date }

            case "avg_rpe":
                return workouts.compactMap { date, dayWorkouts -> (Date, Double)? in
                    var rpeSum = 0.0
                    var rpeCount = 0
                    for workout in dayWorkouts {
                        for we in workout.workoutExercises {
                            for set in we.sets {
                                if let rpe = getFieldValue(set, systemKey: "rpe") {
                                    rpeSum += rpe
                                    rpeCount += 1
                                }
                            }
                        }
                    }
                    return rpeCount > 0 ? (date, rpeSum / Double(rpeCount)) : nil
                }.sorted { $0.date < $1.date }

            case "pr_frequency":
                // PR frequency: count of PRs per training day (simplified — count sets that are max weight for that
                // exercise)
                // Full PR detection would need historical context; for Phase 1, return 0 for all days
                return workouts.map { date, _ in (date, 0.0) }.sorted { $0.0 < $1.0 }

            default:
                return []
        }
    }

    // MARK: - Nutrition Variable Extraction

    // swiftlint:disable:next cyclomatic_complexity
    private func extractNutritionVariable(
        _ variable: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, value: Double)] {
        let meals = try fetchMealEntries(userId: userId, dateRange: dateRange)
        let apiKeyMap = try fetchNutrientApiKeyMap(userId: userId)

        switch variable.id {
            case "daily_calories":
                guard let calorieDefId = apiKeyMap["energy-kcal"] else { return [] }
                return computeDailyNutrientTotals(meals: meals, nutrientDefId: calorieDefId)

            case "daily_protein_g":
                guard let proteinDefId = apiKeyMap["proteins"] else { return [] }
                return computeDailyNutrientTotals(meals: meals, nutrientDefId: proteinDefId)

            case "daily_carbs_g":
                guard let carbsDefId = apiKeyMap["carbohydrates"] else { return [] }
                return computeDailyNutrientTotals(meals: meals, nutrientDefId: carbsDefId)

            case "daily_fat_g":
                guard let fatDefId = apiKeyMap["fat"] else { return [] }
                return computeDailyNutrientTotals(meals: meals, nutrientDefId: fatDefId)

            case "meal_timing_hours":
                return try computeMealTiming(userId: userId, dateRange: dateRange)

            case "caloric_surplus_deficit":
                // Requires TDEE estimation from user profile — skip if profile incomplete
                return []

            case _ where variable.id.hasPrefix("nutrient_"):
                guard let nutrientDefId = variable.nutrientDefinitionId else { return [] }
                return computeDailyNutrientTotals(meals: meals, nutrientDefId: nutrientDefId)

            default:
                return []
        }
    }

    // MARK: - Lifestyle Variable Extraction

    // swiftlint:disable:next cyclomatic_complexity
    private func extractLifestyleVariable(
        _ variable: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, value: Double)] {
        let logs = try fetchDailyLogs(userId: userId, dateRange: dateRange)

        // Custom field
        if variable.id.hasPrefix("custom_"), let fieldId = variable.customFieldId {
            return logs.compactMap { date, log -> (Date, Double)? in
                for value in log.values where value.fieldDefinition.id == fieldId {
                    if let num = value.valueNumber {
                        return (date, Double(num))
                    }
                }
                return nil
            }.sorted { $0.0 < $1.0 }
        }

        // Built-in lifestyle fields
        let keyPath: (DailyLog) -> Double? = switch variable.id {
            case "sleep_hours": { log in log.sleepHours.map { Double($0) } }
            case "sleep_deep_minutes": { log in log.sleepDeepMinutes.map { Double($0) } }
            case "sleep_core_minutes": { log in log.sleepCoreMinutes.map { Double($0) } }
            case "sleep_rem_minutes": { log in log.sleepRemMinutes.map { Double($0) } }
            case "steps": { log in log.steps.map { Double($0) } }
            case "resting_hr": { log in log.restingHeartRate.map { Double($0) } }
            case "hrv": { log in log.hrv.map { Double($0) } }
            case "active_energy_kcal": { log in log.activeEnergyKcal.map { Double($0) } }
            case "walking_distance_km": { log in log.walkingDistanceKm.map { Double($0) } }
            default: { _ in nil }
        }

        return logs.compactMap { date, log -> (Date, Double)? in
            guard let value = keyPath(log) else { return nil }
            return (date, value)
        }.sorted { $0.0 < $1.0 }
    }

    // MARK: - Derived Variable Extraction

    private func extractDerivedVariable(
        _ variable: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, value: Double)] {
        switch variable.id {
            case "training_day":
                let workouts = try fetchWorkouts(userId: userId, dateRange: dateRange)
                let calendar = Calendar.current
                let trainingDates = Set(workouts.keys)

                var results: [(Date, Double)] = []
                var current = calendar.startOfDay(for: dateRange.lowerBound)
                while current <= dateRange.upperBound {
                    let value: Double = trainingDates.contains(current) ? 1.0 : 0.0
                    results.append((current, value))
                    guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                    current = next
                }
                return results

            case "time_of_day_bucket":
                // For categorical, this is handled via extractLabels instead
                return []

            default:
                return []
        }
    }

    // MARK: - Label Extraction (for categorical/binary variables)

    // swiftlint:disable:next cyclomatic_complexity
    private func extractLabels(
        variable: CorrelationVariable,
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, label: String)] {
        switch variable.id {
            case "training_day":
                let workouts = try fetchWorkouts(userId: userId, dateRange: dateRange)
                let calendar = Calendar.current
                let trainingDates = Set(workouts.keys)

                var results: [(Date, String)] = []
                var current = calendar.startOfDay(for: dateRange.lowerBound)
                while current <= dateRange.upperBound {
                    let label = trainingDates.contains(current) ? "yes" : "no"
                    results.append((current, label))
                    guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                    current = next
                }
                return results

            case "time_of_day_bucket":
                let workouts = try fetchWorkouts(userId: userId, dateRange: dateRange)
                return workouts.compactMap { date, dayWorkouts -> (Date, String)? in
                    guard let workout = dayWorkouts.first, let startedAt = workout.startedAt else { return nil }
                    let hour = Calendar.current.component(.hour, from: startedAt)
                    let bucket = if hour < 12 { "morning" } else if hour < 17 { "afternoon" } else { "evening" }
                    return (date, bucket)
                }.sorted { $0.0 < $1.0 }

            default:
                // Custom toggle/categorical fields
                if variable.id.hasPrefix("custom_"), let fieldId = variable.customFieldId {
                    let logs = try fetchDailyLogs(userId: userId, dateRange: dateRange)
                    return logs.compactMap { date, log -> (Date, String)? in
                        for value in log.values where value.fieldDefinition.id == fieldId {
                            if let toggle = value.valueToggle {
                                return (date, toggle ? "yes" : "no")
                            }
                            if let text = value.valueText, !text.isEmpty {
                                return (date, text)
                            }
                        }
                        return nil
                    }.sorted { $0.0 < $1.0 }
                }
                return []
        }
    }

    // MARK: - Data Fetching (with caching)

    private func fetchWorkouts(userId: UUID, dateRange: ClosedRange<Date>) throws -> [Date: [Workout]] {
        if let cached = workoutCache { return cached }

        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.user.id == userId
                    && workout.status == "completed"
                    && workout.date >= startDate
                    && workout.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        let workouts = try modelContext.fetch(descriptor)

        let calendar = Calendar.current
        var byDate: [Date: [Workout]] = [:]
        for workout in workouts {
            let date = calendar.startOfDay(for: workout.date)
            byDate[date, default: []].append(workout)
        }

        workoutCache = byDate
        return byDate
    }

    private func fetchMealEntries(userId: UUID, dateRange: ClosedRange<Date>) throws -> [Date: [MealEntry]] {
        if let cached = mealEntryCache { return cached }

        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { meal in
                meal.user.id == userId
                    && meal.date >= startDate
                    && meal.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        let entries = try modelContext.fetch(descriptor)

        let calendar = Calendar.current
        var byDate: [Date: [MealEntry]] = [:]
        for entry in entries {
            let date = calendar.startOfDay(for: entry.date)
            byDate[date, default: []].append(entry)
        }

        mealEntryCache = byDate
        return byDate
    }

    private func fetchDailyLogs(userId: UUID, dateRange: ClosedRange<Date>) throws -> [Date: DailyLog] {
        if let cached = dailyLogCache { return cached }

        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.user.id == userId
                    && log.date >= startDate
                    && log.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        let logs = try modelContext.fetch(descriptor)

        let calendar = Calendar.current
        var byDate: [Date: DailyLog] = [:]
        for log in logs {
            byDate[calendar.startOfDay(for: log.date)] = log
        }

        dailyLogCache = byDate
        return byDate
    }

    private func fetchNutrientApiKeyMap(userId: UUID) throws -> [String: UUID] {
        if let cached = nutrientApiKeyToId { return cached }

        let descriptor = FetchDescriptor<NutrientDefinition>(
            predicate: #Predicate<NutrientDefinition> { def in
                def.user.id == userId
            }
        )
        let definitions = try modelContext.fetch(descriptor)

        var map: [String: UUID] = [:]
        for def in definitions {
            if let key = def.apiKey {
                map[key] = def.id
            }
        }

        nutrientApiKeyToId = map
        nutrientDefinitionsCache = definitions
        return map
    }

    // MARK: - Computation Helpers

    private func computeSessionVolume(_ workout: Workout) -> Double {
        var volume = 0.0
        for we in workout.workoutExercises {
            for set in we.sets {
                let weight = getFieldValue(set, systemKey: "weight") ?? 0
                let reps = getFieldValue(set, systemKey: "reps") ?? 0
                volume += weight * reps
            }
        }
        return volume
    }

    private func computeMuscleGroupVolume(_ workout: Workout, muscleGroup: String) -> Double {
        var volume = 0.0
        for we in workout.workoutExercises {
            guard let exercise = we.exercise, exercise.muscleGroups.contains(muscleGroup) else { continue }
            for set in we.sets {
                let weight = getFieldValue(set, systemKey: "weight") ?? 0
                let reps = getFieldValue(set, systemKey: "reps") ?? 0
                volume += weight * reps
            }
        }
        return volume
    }

    /// Epley formula: e1RM = weight × (1 + reps / 30). Only for sets with reps <= 10.
    private func computeE1RM(_ set: WorkoutSet) -> Double? {
        guard let weight = getFieldValue(set, systemKey: "weight"),
              let reps = getFieldValue(set, systemKey: "reps"),
              weight > 0, reps > 0, reps <= 10
        else { return nil }
        return weight * (1.0 + reps / 30.0)
    }

    private func countSetsToFailure(_ workout: Workout) -> Int {
        var count = 0
        for we in workout.workoutExercises {
            for set in we.sets {
                // RPE of 10 indicates failure
                if let rpe = getFieldValue(set, systemKey: "rpe"), rpe >= 10.0 {
                    count += 1
                }
            }
        }
        return count
    }

    private func getFieldValue(_ set: WorkoutSet, systemKey: String) -> Double? {
        for value in set.values where value.fieldDefinition.systemKey == systemKey {
            if let num = value.valueNumber {
                return Double(num)
            }
        }
        return nil
    }

    private func computeDailyNutrientTotals(
        meals: [Date: [MealEntry]],
        nutrientDefId: UUID
    ) -> [(date: Date, value: Double)] {
        meals.compactMap { date, entries -> (Date, Double)? in
            var total = 0.0
            for entry in entries {
                guard let food = entry.foodItem else { continue }
                for nutrient in food.nutrients where nutrient.nutrientDefinition.id == nutrientDefId {
                    total += Double(nutrient.valuePerServing * entry.quantity)
                }
            }
            return total > 0 ? (date, total) : nil
        }.sorted { $0.0 < $1.0 }
    }

    /// Compute hours between last pre-workout meal and workout start, for each training day.
    private func computeMealTiming(
        userId: UUID,
        dateRange: ClosedRange<Date>
    ) throws -> [(date: Date, value: Double)] {
        let workouts = try fetchWorkouts(userId: userId, dateRange: dateRange)
        let meals = try fetchMealEntries(userId: userId, dateRange: dateRange)

        var results: [(Date, Double)] = []

        for (date, dayWorkouts) in workouts {
            guard let workout = dayWorkouts.first, let startedAt = workout.startedAt else { continue }

            // Find meals on this date logged before workout start
            guard let dayMeals = meals[date] else { continue }
            let preMeals = dayMeals.filter { $0.loggedAt < startedAt }
            guard let lastMeal = preMeals.max(by: { $0.loggedAt < $1.loggedAt }) else { continue }

            let hours = startedAt.timeIntervalSince(lastMeal.loggedAt) / 3600.0
            if hours > 0, hours < 24 {
                results.append((date, hours))
            }
        }

        return results.sorted { $0.0 < $1.0 }
    }
}
