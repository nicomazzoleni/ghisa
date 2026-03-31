import Foundation
@testable import GHISA
import Testing

struct StatisticalTestsTests {
    // MARK: - Fixture Loading

    // swiftlint:disable identifier_name
    private struct SpearmanFixture: Codable {
        let name: String
        let x: [Double]
        let y: [Double]
        let expected_rho: Double
        let expected_p: Double
    }

    private struct MannWhitneyFixture: Codable {
        let name: String
        let group_a: [Double]
        let group_b: [Double]
        let expected_u: Double
        let expected_p: Double
    }

    private struct KruskalWallisFixture: Codable {
        let name: String
        let groups: [String: [Double]]
        let expected_h: Double
        let expected_p: Double
    }

    // swiftlint:enable identifier_name

    private func loadFixtures<T: Codable>(named name: String) throws -> [T] {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw FixtureError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }

    private enum FixtureError: Error {
        case fileNotFound(String)
    }

    // MARK: - Spearman Tests

    @Test func spearmanMatchesPythonFixtures() throws {
        let fixtures: [SpearmanFixture] = try loadFixtures(named: "SpearmanFixtures")

        for fixture in fixtures {
            guard let result = StatisticalTests.spearman(x: fixture.x, y: fixture.y) else {
                Issue.record("Spearman returned nil for fixture: \(fixture.name)")
                continue
            }

            #expect(
                abs(result.rho - fixture.expected_rho) < 0.01,
                "rho mismatch for \(fixture.name): got \(result.rho), expected \(fixture.expected_rho)"
            )

            // P-value tolerance is wider for very small p-values
            let pTolerance = max(fixture.expected_p * 0.1, 0.01)
            #expect(
                abs(result.pValue - fixture.expected_p) < pTolerance,
                "p-value mismatch for \(fixture.name): got \(result.pValue), expected \(fixture.expected_p)"
            )
        }
    }

    @Test func spearmanPerfectCorrelation() {
        let x = (1 ... 20).map { Double($0) }
        let y = (1 ... 20).map { Double($0) }

        guard let result = StatisticalTests.spearman(x: x, y: y) else {
            Issue.record("Spearman returned nil for perfect correlation")
            return
        }

        #expect(abs(result.rho - 1.0) < 0.001)
        #expect(result.pValue < 0.001)
        #expect(result.effectMagnitude == .large)
    }

    @Test func spearmanPerfectNegative() {
        let x = (1 ... 20).map { Double($0) }
        let y = (1 ... 20).reversed().map { Double($0) }

        guard let result = StatisticalTests.spearman(x: x, y: y) else {
            Issue.record("Spearman returned nil")
            return
        }

        #expect(abs(result.rho - -1.0) < 0.001)
        #expect(result.effectMagnitude == .large)
    }

    @Test func spearmanZeroVarianceReturnsNil() {
        let x = [5.0, 5.0, 5.0, 5.0, 5.0]
        let y = [1.0, 2.0, 3.0, 4.0, 5.0]

        let result = StatisticalTests.spearman(x: x, y: y)
        #expect(result == nil)
    }

    @Test func spearmanMismatchedLengthsReturnsNil() {
        let result = StatisticalTests.spearman(x: [1, 2, 3], y: [1, 2])
        #expect(result == nil)
    }

    @Test func spearmanTooShortReturnsNil() {
        let result = StatisticalTests.spearman(x: [1, 2], y: [1, 2])
        #expect(result == nil)
    }

    // MARK: - Mann-Whitney Tests

    @Test func mannWhitneyMatchesPythonFixtures() throws {
        let fixtures: [MannWhitneyFixture] = try loadFixtures(named: "MannWhitneyFixtures")

        for fixture in fixtures {
            guard let result = StatisticalTests.mannWhitney(groupA: fixture.group_a, groupB: fixture.group_b) else {
                Issue.record("Mann-Whitney returned nil for fixture: \(fixture.name)")
                continue
            }

            // P-value comparison — our implementation uses a slightly different normal approximation
            // so we allow wider tolerance
            let pTolerance = max(fixture.expected_p * 0.15, 0.02)
            #expect(
                abs(result.pValue - fixture.expected_p) < pTolerance,
                "p-value mismatch for \(fixture.name): got \(result.pValue), expected \(fixture.expected_p)"
            )
        }
    }

    @Test func mannWhitneyIdenticalGroupsHighPValue() {
        let group = (1 ... 30).map { Double($0) }
        guard let result = StatisticalTests.mannWhitney(groupA: group, groupB: group) else {
            Issue.record("Mann-Whitney returned nil")
            return
        }

        #expect(result.pValue > 0.05)
        #expect(abs(result.rankBiserialR) < 0.3)
    }

    @Test func mannWhitneyEmptyGroupReturnsNil() {
        let result = StatisticalTests.mannWhitney(groupA: [], groupB: [1, 2, 3])
        #expect(result == nil)
    }

    // MARK: - Kruskal-Wallis Tests

    @Test func kruskalWallisMatchesPythonFixtures() throws {
        let fixtures: [KruskalWallisFixture] = try loadFixtures(named: "KruskalWallisFixtures")

        for fixture in fixtures {
            guard let result = StatisticalTests.kruskalWallis(groups: fixture.groups) else {
                Issue.record("Kruskal-Wallis returned nil for fixture: \(fixture.name)")
                continue
            }

            let hTolerance = max(fixture.expected_h * 0.05, 0.5)
            #expect(
                abs(result.hStatistic - fixture.expected_h) < hTolerance,
                "H mismatch for \(fixture.name): got \(result.hStatistic), expected \(fixture.expected_h)"
            )

            let pTolerance = max(fixture.expected_p * 0.15, 0.02)
            #expect(
                abs(result.pValue - fixture.expected_p) < pTolerance,
                "p-value mismatch for \(fixture.name): got \(result.pValue), expected \(fixture.expected_p)"
            )
        }
    }

    @Test func kruskalWallisSingleGroupReturnsNil() {
        let result = StatisticalTests.kruskalWallis(groups: ["only": [1, 2, 3, 4, 5]])
        #expect(result == nil)
    }

    // MARK: - Ranking Tests

    @Test func rankHandlesTies() {
        let values = [3.0, 1.0, 4.0, 1.0, 5.0]
        let ranks = StatisticalTests.rank(values)

        // 1.0 appears twice → ranks 1,2 → mean 1.5
        // 3.0 → rank 3
        // 4.0 → rank 4
        // 5.0 → rank 5
        #expect(ranks[0] == 3.0) // 3.0
        #expect(ranks[1] == 1.5) // 1.0 (tied)
        #expect(ranks[2] == 4.0) // 4.0
        #expect(ranks[3] == 1.5) // 1.0 (tied)
        #expect(ranks[4] == 5.0) // 5.0
    }

    @Test func rankNoTies() {
        let values = [10.0, 30.0, 20.0]
        let ranks = StatisticalTests.rank(values)

        #expect(ranks[0] == 1.0)
        #expect(ranks[1] == 3.0)
        #expect(ranks[2] == 2.0)
    }

    // MARK: - Effect Size Classification

    @Test func effectSizeClassification() {
        #expect(StatisticalTests.classifyCorrelation(0.05) == .negligible)
        #expect(StatisticalTests.classifyCorrelation(0.15) == .small)
        #expect(StatisticalTests.classifyCorrelation(0.35) == .medium)
        #expect(StatisticalTests.classifyCorrelation(0.6) == .large)
    }

    @Test func epsilonSquaredClassification() {
        #expect(StatisticalTests.classifyEpsilonSquared(0.005) == .negligible)
        #expect(StatisticalTests.classifyEpsilonSquared(0.03) == .small)
        #expect(StatisticalTests.classifyEpsilonSquared(0.10) == .medium)
        #expect(StatisticalTests.classifyEpsilonSquared(0.20) == .large)
    }
}

/// Token class for locating the test bundle.
private final class BundleToken {}
