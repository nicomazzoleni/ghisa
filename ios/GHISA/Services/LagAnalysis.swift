import Foundation

// MARK: - Lag Result

struct LagResult {
    let bestLag: Int
    let bestResult: PairwiseTestResult
    let allResults: [Int: PairwiseTestResult]
}

// MARK: - Lag Test Parameters

struct LagTestParameters {
    let target: CorrelationVariable
    let factor: CorrelationVariable
    let extractionService: DataExtractionService
    let userId: UUID
    let dateRange: ClosedRange<Date>
}

// MARK: - Lag Analysis

enum LagAnalysis {
    /// Analyze lags 0 through maxLag for a target-factor pair.
    /// Returns nil if no lag has sufficient sample size (n >= 20).
    static func analyzeLags(
        target: CorrelationVariable,
        factor: CorrelationVariable,
        extractionService: DataExtractionService,
        userId: UUID,
        dateRange: ClosedRange<Date>,
        maxLag: Int = 7,
        minSampleSize: Int = 20
    ) throws -> LagResult? {
        let params = LagTestParameters(
            target: target, factor: factor,
            extractionService: extractionService,
            userId: userId, dateRange: dateRange
        )

        var allResults: [Int: PairwiseTestResult] = [:]

        for lag in 0 ... maxLag {
            let result: PairwiseTestResult? = switch factor.variableType {
                case .continuous, .ordinal:
                    try testContinuousLag(
                        params: params, lag: lag, minSampleSize: minSampleSize
                    )

                case .binary, .categorical:
                    try testGroupedLag(
                        params: params, lag: lag, minSampleSize: minSampleSize
                    )
            }

            if let result {
                allResults[lag] = result
            }
        }

        guard !allResults.isEmpty else { return nil }

        // Pick the lag with the smallest p-value
        guard let bestEntry = allResults.min(by: { $0.value.pValue < $1.value.pValue }) else { return nil }
        var bestLag = bestEntry.key
        var bestResult = bestEntry.value

        // Autocorrelation mitigation: if best lag > 0, check partial correlation controlling for lag 0
        // swiftlint:disable opening_brace
        if bestLag > 0,
           factor.variableType == .continuous || factor.variableType == .ordinal,
           let lag0Result = allResults[0]
        {
            // swiftlint:enable opening_brace
            let partialIsSignificant = try checkPartialCorrelation(
                params: params,
                testLag: bestLag, controlLag: 0,
                minSampleSize: minSampleSize
            )

            // If partial correlation is not significant, collapse to lag 0
            if !partialIsSignificant {
                bestLag = 0
                bestResult = lag0Result
            }
        }

        return LagResult(
            bestLag: bestLag,
            bestResult: bestResult,
            allResults: allResults
        )
    }

    // MARK: - Private: Test at a specific lag

    private static func testContinuousLag(
        params: LagTestParameters,
        lag: Int,
        minSampleSize: Int
    ) throws -> PairwiseTestResult? {
        let paired = try params.extractionService.extractPairedData(
            target: params.target, factor: params.factor,
            userId: params.userId, dateRange: params.dateRange, lagDays: lag
        )

        guard paired.sampleSize >= minSampleSize else { return nil }

        guard let result = StatisticalTests.spearman(x: paired.targetValues, y: paired.factorValues) else {
            return nil
        }

        let bucketMeans = params.extractionService.computeBucketMeans(
            targetValues: paired.targetValues, factorValues: paired.factorValues
        )

        return PairwiseTestResult(
            targetVariable: params.target.id,
            factorVariable: params.factor.id,
            lagDays: lag,
            pValue: result.pValue,
            effectSize: result.rho,
            effectMagnitude: result.effectMagnitude,
            testMethod: "spearman",
            sampleSize: paired.sampleSize,
            dataCompleteness: paired.dataCompleteness,
            meanHigh: bucketMeans?.meanHigh,
            meanLow: bucketMeans?.meanLow
        )
    }

    private static func testGroupedLag(
        params: LagTestParameters,
        lag: Int,
        minSampleSize: Int
    ) throws -> PairwiseTestResult? {
        let grouped = try params.extractionService.extractGroupedData(
            target: params.target, factor: params.factor,
            userId: params.userId, dateRange: params.dateRange, lagDays: lag
        )

        guard grouped.sampleSize >= minSampleSize else { return nil }

        if params.factor.variableType == .binary {
            // Mann-Whitney for binary
            let groupValues = Array(grouped.targetValuesByGroup.values)
            guard groupValues.count == 2 else { return nil }

            guard let result = StatisticalTests.mannWhitney(groupA: groupValues[0], groupB: groupValues[1]) else {
                return nil
            }

            // Compute means for HIGH/LOW
            let sortedGroups = grouped.targetValuesByGroup.sorted { $0.key < $1.key }
            let meanFirst = sortedGroups[0].value.isEmpty ? nil : sortedGroups[0].value
                .reduce(0, +) / Double(sortedGroups[0].value.count)
            let meanSecond = sortedGroups[1].value.isEmpty ? nil : sortedGroups[1].value
                .reduce(0, +) / Double(sortedGroups[1].value.count)

            return PairwiseTestResult(
                targetVariable: params.target.id,
                factorVariable: params.factor.id,
                lagDays: lag,
                pValue: result.pValue,
                effectSize: result.rankBiserialR,
                effectMagnitude: result.effectMagnitude,
                testMethod: "mann_whitney",
                sampleSize: grouped.sampleSize,
                dataCompleteness: grouped.dataCompleteness,
                meanHigh: meanSecond,
                meanLow: meanFirst
            )
        } else {
            // Kruskal-Wallis for categorical
            guard let result = StatisticalTests.kruskalWallis(groups: grouped.targetValuesByGroup) else {
                return nil
            }

            return PairwiseTestResult(
                targetVariable: params.target.id,
                factorVariable: params.factor.id,
                lagDays: lag,
                pValue: result.pValue,
                effectSize: result.epsilonSquared,
                effectMagnitude: result.effectMagnitude,
                testMethod: "kruskal_wallis",
                sampleSize: grouped.sampleSize,
                dataCompleteness: grouped.dataCompleteness,
                meanHigh: nil,
                meanLow: nil
            )
        }
    }

    // MARK: - Partial Correlation Check

    /// Check if the correlation at `testLag` remains significant after controlling for `controlLag`.
    /// Uses Spearman partial correlation formula.
    private static func checkPartialCorrelation(
        params: LagTestParameters,
        testLag: Int,
        controlLag: Int,
        minSampleSize: Int
    ) throws -> Bool {
        // Get three sets of paired data aligned on the same dates
        let pairedTest = try params.extractionService.extractPairedData(
            target: params.target, factor: params.factor,
            userId: params.userId, dateRange: params.dateRange, lagDays: testLag
        )
        let pairedControl = try params.extractionService.extractPairedData(
            target: params.target, factor: params.factor,
            userId: params.userId, dateRange: params.dateRange, lagDays: controlLag
        )

        guard pairedTest.sampleSize >= minSampleSize,
              pairedControl.sampleSize >= minSampleSize
        else { return false }

        // Compute pairwise Spearman correlations
        guard let rhoXY = StatisticalTests.spearman(x: pairedTest.targetValues, y: pairedTest.factorValues),
              let rhoXZ = StatisticalTests.spearman(x: pairedControl.targetValues, y: pairedControl.factorValues)
        else { return false }

        // Also need correlation between factor at test lag and factor at control lag
        // Approximate by using the factor values directly
        let factorTestControl = try params.extractionService.extractPairedData(
            target: params.factor, factor: params.factor,
            userId: params.userId, dateRange: params.dateRange, lagDays: abs(testLag - controlLag)
        )
        guard let rhoYZ = StatisticalTests
            .spearman(x: factorTestControl.targetValues, y: factorTestControl.factorValues)
        else {
            return false
        }

        // Partial correlation formula
        let numerator = rhoXY.rho - rhoXZ.rho * rhoYZ.rho
        let denominator = sqrt((1 - rhoXZ.rho * rhoXZ.rho) * (1 - rhoYZ.rho * rhoYZ.rho))

        guard denominator > 0 else { return false }

        let rhoPartial = numerator / denominator
        let n = Double(min(pairedTest.sampleSize, pairedControl.sampleSize))
        let pPartial = StatisticalTests.spearmanPValue(rho: rhoPartial, n: n - 1) // df reduced by 1 for control

        return pPartial < 0.05
    }
}
