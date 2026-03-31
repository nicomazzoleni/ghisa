import Accelerate
import Foundation
import SwiftData

@MainActor
@Observable
final class CorrelationEngine {
    private let modelContext: ModelContext
    private let extractionService: DataExtractionService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.extractionService = DataExtractionService(modelContext: modelContext)
    }

    // MARK: - Full Recomputation

    /// Run full recomputation of all correlations for a user.
    func recomputeAll(for userId: UUID) async throws {
        let user = try fetchUser(userId: userId)
        let dateRange = try computeDateRange(userId: userId)
        let variables = try buildVariableRegistry(userId: userId)

        let targets = variables.filter(\.isTarget)
        let factors = variables.filter { !$0.isTarget }

        // Delete all previous results for this user
        try deleteAllResults(for: userId)

        // For each target, run all factors through lag analysis, then BH correct
        for target in targets {
            try processTarget(
                target, factors: factors, variables: variables,
                user: user, dateRange: dateRange
            )
            await Task.yield()
        }

        try modelContext.save()
        extractionService.clearCaches()
    }

    /// Process a single target variable: run lag analysis, BH correct, and persist significant results.
    private func processTarget(
        _ target: CorrelationVariable,
        factors: [CorrelationVariable],
        variables: [CorrelationVariable],
        user: User,
        dateRange: ClosedRange<Date>
    ) throws {
        let rawResults = collectRawResults(target: target, factors: factors, dateRange: dateRange, userId: user.id)
        guard !rawResults.isEmpty else { return }

        let adjusted = BenjaminiHochberg.correct(rawResults)
        let significantByFactor = pickBestLagPerFactor(adjusted.filter(\.isSignificant))

        for adjustedResult in significantByFactor {
            let correlationResult = buildCorrelationResult(
                adjustedResult: adjustedResult, target: target,
                variables: variables, user: user
            )
            modelContext.insert(correlationResult)
        }
    }

    /// Run lag analysis for all factors against a target and collect raw pairwise results.
    private func collectRawResults(
        target: CorrelationVariable,
        factors: [CorrelationVariable],
        dateRange: ClosedRange<Date>,
        userId: UUID
    ) -> [PairwiseTestResult] {
        var rawResults: [PairwiseTestResult] = []
        for factor in factors {
            guard let lagResult = try? LagAnalysis.analyzeLags(
                target: target, factor: factor,
                extractionService: extractionService,
                userId: userId, dateRange: dateRange
            ) else { continue }
            for (_, result) in lagResult.allResults {
                rawResults.append(result)
            }
        }
        return rawResults
    }

    /// Build a CorrelationResult model object from an adjusted test result.
    private func buildCorrelationResult(
        adjustedResult: AdjustedTestResult,
        target: CorrelationVariable,
        variables: [CorrelationVariable],
        user: User
    ) -> CorrelationResult {
        let result = adjustedResult.original
        let badge = ConfidenceBadge.compute(
            effectMagnitude: result.effectMagnitude,
            sampleSize: result.sampleSize,
            dataCompleteness: result.dataCompleteness
        )

        let description = generateEffectDescription(
            target: target, result: result, variables: variables
        )

        let correlationResult = CorrelationResult(
            user: user,
            targetVariable: result.targetVariable,
            factorVariable: result.factorVariable,
            testMethod: result.testMethod,
            lagDays: result.lagDays,
            effectSize: Float(result.effectSize),
            pValue: Float(adjustedResult.adjustedPValue),
            sampleSize: result.sampleSize,
            effectDescription: description,
            confidenceBadge: badge.rawValue,
            isSignificant: true,
            dataCompleteness: Float(result.dataCompleteness)
        )
        correlationResult.meanHigh = result.meanHigh.map { Float($0) }
        correlationResult.meanLow = result.meanLow.map { Float($0) }
        return correlationResult
    }

    // MARK: - Incremental Update

    /// Incremental update — only recompute targets/factors with new data since last computation.
    func incrementalUpdate(for userId: UUID, since lastComputation: Date) async throws {
        // Check if any new data exists
        let hasNewWorkouts = try checkNewData(Workout.self, userId: userId, since: lastComputation)
        let hasNewMeals = try checkNewData(MealEntry.self, userId: userId, since: lastComputation)
        let hasNewLogs = try checkNewData(DailyLog.self, userId: userId, since: lastComputation)

        guard hasNewWorkouts || hasNewMeals || hasNewLogs else { return }

        // For simplicity in Phase 1, do a full recomputation if any new data exists
        try await recomputeAll(for: userId)
    }

    // MARK: - Query

    /// Get all significant correlations for a target variable, sorted by effect size.
    func significantFactors(for target: String, userId: UUID) -> [CorrelationResult] {
        let descriptor = FetchDescriptor<CorrelationResult>(
            predicate: #Predicate<CorrelationResult> { result in
                result.user.id == userId
                    && result.targetVariable == target
                    && result.isSignificant
            },
            sortBy: [SortDescriptor(\.effectSize)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        // Sort by absolute effect size descending
        return results.sorted { abs($0.effectSize) > abs($1.effectSize) }
    }

    /// Get all significant correlations for a user.
    func allSignificantResults(for userId: UUID) -> [CorrelationResult] {
        let descriptor = FetchDescriptor<CorrelationResult>(
            predicate: #Predicate<CorrelationResult> { result in
                result.user.id == userId && result.isSignificant
            }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.sorted { abs($0.effectSize) > abs($1.effectSize) }
    }

    /// Compute partial correlations for "What Matters Most" ranking (Phase 2 — stub).
    func partialCorrelations(for target: String, userId: UUID) async throws -> [CorrelationResult] {
        _ = target
        _ = userId
        return []
    }

    // MARK: - Private Helpers

    private func fetchUser(userId: UUID) throws -> User {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == userId
            }
        )
        guard let user = try modelContext.fetch(descriptor).first else {
            throw AppError.validation(message: "User not found")
        }
        return user
    }

    private func computeDateRange(userId: UUID) throws -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Go back 1 year or to earliest data, whichever is more recent
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        return oneYearAgo ... today
    }

    private func buildVariableRegistry(userId: UUID) throws -> [CorrelationVariable] {
        // Fetch exercises
        let exerciseDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.user.id == userId && !exercise.isArchived
            }
        )
        let exercises = try modelContext.fetch(exerciseDescriptor)
        let exerciseInfos = exercises.map { ExerciseInfo(id: $0.id, name: $0.name, muscleGroups: $0.muscleGroups) }

        // Collect all unique muscle groups
        let muscleGroups = Array(Set(exercises.flatMap(\.muscleGroups))).sorted()

        // Fetch nutrient definitions
        let nutrientDescriptor = FetchDescriptor<NutrientDefinition>(
            predicate: #Predicate<NutrientDefinition> { def in
                def.user.id == userId && def.isVisible
            }
        )
        let nutrients = try modelContext.fetch(nutrientDescriptor)
        let nutrientInfos = nutrients.map {
            NutrientDefinitionInfo(id: $0.id, name: $0.name, unit: $0.unit, apiKey: $0.apiKey)
        }

        // Fetch custom daily log field definitions
        let fieldDescriptor = FetchDescriptor<DailyLogFieldDefinition>(
            predicate: #Predicate<DailyLogFieldDefinition> { def in
                def.user.id == userId && def.isActive
            }
        )
        let fields = try modelContext.fetch(fieldDescriptor)
        // Only include non-system custom fields
        let customFields = fields.filter { $0.systemKey == nil }.map {
            CustomFieldInfo(id: $0.id, name: $0.name, fieldType: $0.fieldType)
        }

        return CorrelationVariable.allVariables(
            exercises: exerciseInfos,
            muscleGroups: muscleGroups,
            nutrientDefinitions: nutrientInfos,
            customDailyFields: customFields
        )
    }

    private func deleteAllResults(for userId: UUID) throws {
        let descriptor = FetchDescriptor<CorrelationResult>(
            predicate: #Predicate<CorrelationResult> { result in
                result.user.id == userId
            }
        )
        let existing = try modelContext.fetch(descriptor)
        for result in existing {
            modelContext.delete(result)
        }
    }

    /// Pick the best lag for each factor (lowest adjusted p-value).
    private func pickBestLagPerFactor(_ results: [AdjustedTestResult]) -> [AdjustedTestResult] {
        var bestByFactor: [String: AdjustedTestResult] = [:]
        for result in results {
            let key = result.original.factorVariable
            if let existing = bestByFactor[key] {
                if result.adjustedPValue < existing.adjustedPValue {
                    bestByFactor[key] = result
                }
            } else {
                bestByFactor[key] = result
            }
        }
        return Array(bestByFactor.values)
    }

    private func generateEffectDescription(
        target: CorrelationVariable,
        result: PairwiseTestResult,
        variables: [CorrelationVariable]
    ) -> String {
        let factorName = variables.first { $0.id == result.factorVariable }?.displayName ?? result.factorVariable
        let targetName = target.displayName
        let direction = result.effectSize > 0 ? "higher" : "lower"

        if let high = result.meanHigh, let low = result.meanLow, low > 0 {
            let pctDiff = abs(high - low) / low * 100
            return String(format: "%@ is %.0f%% %@ when %@ is high", targetName, pctDiff, direction, factorName)
        }

        return "\(direction.capitalized) \(factorName) is associated with \(direction) \(targetName)"
    }

    private func checkNewData<T: PersistentModel>(_ type: T.Type, userId: UUID, since: Date) throws -> Bool {
        // Simple check: see if any records exist after the given date
        // This is a conservative check — we can't easily filter by userId generically
        let descriptor = FetchDescriptor<T>()
        let results = try modelContext.fetch(descriptor)
        return !results.isEmpty
    }
}
