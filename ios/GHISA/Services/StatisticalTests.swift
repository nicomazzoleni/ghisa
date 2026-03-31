// swiftlint:disable identifier_name
import Accelerate
import Foundation

// MARK: - Result Types

struct SpearmanResult {
    let rho: Double
    let pValue: Double
    let effectMagnitude: EffectSizeMagnitude
}

struct MannWhitneyResult {
    let uStatistic: Double
    let pValue: Double
    let rankBiserialR: Double
    let effectMagnitude: EffectSizeMagnitude
}

struct KruskalWallisResult {
    let hStatistic: Double
    let pValue: Double
    let epsilonSquared: Double
    let effectMagnitude: EffectSizeMagnitude
}

enum EffectSizeMagnitude: String {
    case negligible
    case small
    case medium
    case large
}

// MARK: - Statistical Tests

enum StatisticalTests {
    // MARK: - Spearman Rank Correlation

    /// Computes Spearman rank correlation coefficient and two-tailed p-value.
    /// Returns nil if either array has zero variance or arrays are mismatched/too short.
    static func spearman(x: [Double], y: [Double]) -> SpearmanResult? {
        guard x.count == y.count, x.count >= 3 else { return nil }

        let ranksX = rank(x)
        let ranksY = rank(y)

        // Check for zero variance in ranks
        guard hasVariance(ranksX), hasVariance(ranksY) else { return nil }

        let rho = pearson(ranksX, ranksY)
        let n = Double(x.count)
        let pValue = spearmanPValue(rho: rho, n: n)

        return SpearmanResult(
            rho: rho,
            pValue: pValue,
            effectMagnitude: classifyCorrelation(abs(rho))
        )
    }

    // MARK: - Mann-Whitney U Test

    /// Computes Mann-Whitney U test for two independent groups.
    /// `groupA` and `groupB` are the target values for each group.
    /// Returns nil if either group is empty or total n < 3.
    static func mannWhitney(groupA: [Double], groupB: [Double]) -> MannWhitneyResult? {
        let n1 = groupA.count
        let n2 = groupB.count
        guard n1 >= 1, n2 >= 1, n1 + n2 >= 3 else { return nil }

        // Combined ranking
        struct TaggedValue {
            let value: Double
            let group: Int // 0 = A, 1 = B
        }

        let tagged = groupA.map { TaggedValue(value: $0, group: 0) }
            + groupB.map { TaggedValue(value: $0, group: 1) }

        // swiftlint:disable:next unused_enumerated
        let sorted = tagged.enumerated().sorted { $0.element.value < $1.element.value }

        // Assign ranks with tie handling
        let n = n1 + n2
        var ranks = [Double](repeating: 0, count: n)
        var i = 0
        while i < n {
            var j = i
            while j < n - 1, sorted[j + 1].element.value == sorted[i].element.value {
                j += 1
            }
            let meanRank = Double(i + j) / 2.0 + 1.0
            for k in i ... j {
                ranks[sorted[k].offset] = meanRank
            }
            i = j + 1
        }

        // Sum of ranks for group A
        let rankSumA = zip(tagged, ranks)
            .filter { $0.0.group == 0 }
            .reduce(0.0) { $0 + $1.1 }

        let n1d = Double(n1)
        let n2d = Double(n2)

        let u1 = rankSumA - n1d * (n1d + 1) / 2
        let u2 = n1d * n2d - u1
        let u = min(u1, u2)

        // Tie correction for variance
        let tieCorrection = computeTieCorrection(ranks: ranks)
        let nd = Double(n)
        let variance = (n1d * n2d / 12.0)
            * (nd + 1.0 - tieCorrection / (nd * (nd - 1.0)))

        let mean = n1d * n2d / 2.0
        let z: Double = if variance > 0 {
            // Continuity correction
            (abs(u - mean) - 0.5) / sqrt(variance)
        } else {
            0
        }

        let pValue = 2.0 * normalCDFUpperTail(z)

        // Rank-biserial r: effect size
        let rankBiserialR = 1.0 - (2.0 * u) / (n1d * n2d)

        return MannWhitneyResult(
            uStatistic: u,
            pValue: min(pValue, 1.0),
            rankBiserialR: rankBiserialR,
            effectMagnitude: classifyCorrelation(abs(rankBiserialR))
        )
    }

    // MARK: - Kruskal-Wallis H Test

    /// Computes Kruskal-Wallis H test for 2+ independent groups.
    /// `groups` maps group label to array of target values.
    /// Returns nil if fewer than 2 non-empty groups or total n < 3.
    static func kruskalWallis(groups: [String: [Double]]) -> KruskalWallisResult? {
        let nonEmpty = groups.filter { !$0.value.isEmpty }
        guard nonEmpty.count >= 2 else { return nil }

        // Use sorted keys to ensure deterministic ordering
        let sortedKeys = nonEmpty.keys.sorted()
        let allValues = sortedKeys.flatMap { nonEmpty[$0] ?? [] }
        let n = allValues.count
        guard n >= 3 else { return nil }

        // Combined ranking
        // swiftlint:disable:next unused_enumerated
        let indexed = allValues.enumerated().sorted { $0.element < $1.element }
        var ranks = [Double](repeating: 0, count: n)
        var i = 0
        while i < n {
            var j = i
            while j < n - 1, indexed[j + 1].element == indexed[i].element {
                j += 1
            }
            let meanRank = Double(i + j) / 2.0 + 1.0
            for k in i ... j {
                ranks[indexed[k].offset] = meanRank
            }
            i = j + 1
        }

        // Build group rank sums and counts
        var offset = 0
        var groupRankSums: [(count: Int, rankSum: Double)] = []
        for key in sortedKeys {
            let count = (nonEmpty[key] ?? []).count
            let rankSum = ranks[offset ..< offset + count].reduce(0, +)
            groupRankSums.append((count, rankSum))
            offset += count
        }

        let nd = Double(n)
        var hNumerator = 0.0
        for g in groupRankSums {
            let ni = Double(g.count)
            hNumerator += (g.rankSum * g.rankSum) / ni
        }
        var h = (12.0 / (nd * (nd + 1.0))) * hNumerator - 3.0 * (nd + 1.0)

        // Tie correction
        let tieCorrection = computeTieCorrection(ranks: ranks)
        let tieFactor = 1.0 - tieCorrection / (nd * nd * nd - nd)
        if tieFactor > 0 {
            h /= tieFactor
        }

        let df = Double(nonEmpty.count - 1)
        let pValue = chiSquaredUpperTail(x: h, df: df)

        // Epsilon-squared effect size
        let epsilonSquared = (h - df) / (nd - 1.0)
        let clampedEpsilon = max(epsilonSquared, 0)

        return KruskalWallisResult(
            hStatistic: h,
            pValue: min(pValue, 1.0),
            epsilonSquared: clampedEpsilon,
            effectMagnitude: classifyEpsilonSquared(clampedEpsilon)
        )
    }

    // MARK: - Ranking

    /// Assigns ranks to values with mean-rank tie handling.
    static func rank(_ values: [Double]) -> [Double] {
        let n = values.count
        guard n > 0 else { return [] }

        // swiftlint:disable:next unused_enumerated
        let indexed = values.enumerated().sorted { $0.element < $1.element }
        var ranks = [Double](repeating: 0, count: n)

        var i = 0
        while i < n {
            var j = i
            while j < n - 1, indexed[j + 1].element == indexed[i].element {
                j += 1
            }
            let meanRank = Double(i + j) / 2.0 + 1.0
            for k in i ... j {
                ranks[indexed[k].offset] = meanRank
            }
            i = j + 1
        }

        return ranks
    }

    // MARK: - Pearson Correlation (on pre-ranked data)

    static func pearson(_ x: [Double], _ y: [Double]) -> Double {
        let n = x.count
        guard n > 1 else { return 0 }

        var meanX = 0.0
        var meanY = 0.0
        vDSP_meanvD(x, 1, &meanX, vDSP_Length(n))
        vDSP_meanvD(y, 1, &meanY, vDSP_Length(n))

        var sumXY = 0.0
        var sumX2 = 0.0
        var sumY2 = 0.0

        for i in 0 ..< n {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }

        let denom = sqrt(sumX2 * sumY2)
        guard denom > 0 else { return 0 }
        return sumXY / denom
    }

    // MARK: - Effect Size Classification

    /// Classify Spearman ρ or rank-biserial r magnitude.
    static func classifyCorrelation(_ absValue: Double) -> EffectSizeMagnitude {
        if absValue >= 0.5 { return .large }
        if absValue >= 0.3 { return .medium }
        if absValue >= 0.1 { return .small }
        return .negligible
    }

    /// Classify Kruskal-Wallis epsilon-squared magnitude.
    static func classifyEpsilonSquared(_ value: Double) -> EffectSizeMagnitude {
        if value >= 0.14 { return .large }
        if value >= 0.06 { return .medium }
        if value >= 0.01 { return .small }
        return .negligible
    }

    // MARK: - P-Value Helpers

    /// Two-tailed p-value for Spearman using t-distribution approximation.
    static func spearmanPValue(rho: Double, n: Double) -> Double {
        guard n > 2, abs(rho) < 1.0 else {
            return abs(rho) >= 1.0 ? 0.0 : 1.0
        }
        let t = rho * sqrt((n - 2.0) / (1.0 - rho * rho))
        return tDistributionTwoTailP(t: t, df: n - 2.0)
    }

    /// Upper-tail probability of standard normal distribution.
    static func normalCDFUpperTail(_ z: Double) -> Double {
        // P(Z > z) = erfc(z / sqrt(2)) / 2
        erfc(z / sqrt(2.0)) / 2.0
    }

    /// Two-tailed p-value from t-distribution using incomplete beta function approximation.
    static func tDistributionTwoTailP(t: Double, df: Double) -> Double {
        guard df > 0 else { return 1.0 }
        let x = df / (df + t * t)
        let p = regularizedIncompleteBeta(x: x, a: df / 2.0, b: 0.5)
        return min(p, 1.0)
    }

    /// Upper-tail probability of chi-squared distribution: P(X > x) for X ~ χ²(df).
    static func chiSquaredUpperTail(x: Double, df: Double) -> Double {
        guard x > 0, df > 0 else { return 1.0 }
        return regularizedUpperIncompleteGamma(a: df / 2.0, x: x / 2.0)
    }

    // MARK: - Private Helpers

    private static func hasVariance(_ values: [Double]) -> Bool {
        guard let first = values.first else { return false }
        return values.contains { $0 != first }
    }

    /// Compute tie correction term: sum of (t^3 - t) for each group of t tied values.
    static func computeTieCorrection(ranks: [Double]) -> Double {
        var tieCounts: [Double: Int] = [:]
        for r in ranks {
            tieCounts[r, default: 0] += 1
        }
        var correction = 0.0
        for (_, count) in tieCounts where count > 1 {
            let t = Double(count)
            correction += t * t * t - t
        }
        return correction
    }
}

// swiftlint:enable identifier_name
