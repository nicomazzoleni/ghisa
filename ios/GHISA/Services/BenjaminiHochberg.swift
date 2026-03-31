import Foundation

// MARK: - Pairwise Test Result (input to BH correction)

struct PairwiseTestResult {
    let targetVariable: String
    let factorVariable: String
    let lagDays: Int
    let pValue: Double
    let effectSize: Double
    let effectMagnitude: EffectSizeMagnitude
    let testMethod: String
    let sampleSize: Int
    let dataCompleteness: Double
    let meanHigh: Double?
    let meanLow: Double?
}

// MARK: - Adjusted Result (output of BH correction)

struct AdjustedTestResult {
    let original: PairwiseTestResult
    let adjustedPValue: Double
    let isSignificant: Bool
}

// MARK: - Benjamini-Hochberg Procedure

enum BenjaminiHochberg {
    /// Apply Benjamini-Hochberg FDR correction to a set of test results for one target variable.
    /// Returns adjusted results sorted by original p-value ascending.
    static func correct(_ results: [PairwiseTestResult], alpha: Double = 0.05) -> [AdjustedTestResult] {
        guard !results.isEmpty else { return [] }

        let totalTests = Double(results.count)

        // Sort by p-value ascending
        let sorted = results.sorted { $0.pValue < $1.pValue }

        // Compute adjusted p-values
        var adjustedPValues = [Double](repeating: 0, count: sorted.count)

        for (i, result) in sorted.enumerated() {
            let rank = Double(i + 1)
            adjustedPValues[i] = result.pValue * totalTests / rank
        }

        // Enforce monotonicity (walk backward, each value must be <= the next)
        for i in stride(from: sorted.count - 2, through: 0, by: -1) {
            adjustedPValues[i] = min(adjustedPValues[i], adjustedPValues[i + 1])
        }

        // Cap at 1.0 and build results
        return sorted.enumerated().map { i, original in
            let adjP = min(adjustedPValues[i], 1.0)
            return AdjustedTestResult(
                original: original,
                adjustedPValue: adjP,
                isSignificant: adjP < alpha
            )
        }
    }
}
