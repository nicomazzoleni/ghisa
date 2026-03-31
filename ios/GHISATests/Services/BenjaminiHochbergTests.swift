import Foundation
@testable import GHISA
import Testing

struct BenjaminiHochbergTests {
    // MARK: - Fixture Loading

    // swiftlint:disable identifier_name
    private struct BHFixture: Codable {
        let name: String
        let p_values: [Double]
        let expected_adjusted: [Double]
        let expected_significant: [Bool]
    }

    // swiftlint:enable identifier_name

    private func loadFixtures() throws -> [BHFixture] {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: "BenjaminiHochbergFixtures", withExtension: "json") else {
            throw FixtureError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([BHFixture].self, from: data)
    }

    private enum FixtureError: Error {
        case fileNotFound
    }

    // MARK: - Fixture Tests

    @Test func bhMatchesPythonFixtures() throws {
        let fixtures = try loadFixtures()

        for fixture in fixtures {
            let inputs = fixture.p_values.enumerated().map { index, pVal in
                PairwiseTestResult(
                    targetVariable: "target",
                    factorVariable: "factor_\(index)",
                    lagDays: 0,
                    pValue: pVal,
                    effectSize: 0.3,
                    effectMagnitude: .medium,
                    testMethod: "spearman",
                    sampleSize: 50,
                    dataCompleteness: 0.8,
                    meanHigh: nil,
                    meanLow: nil
                )
            }

            let results = BenjaminiHochberg.correct(inputs)

            // Results are sorted by p-value, so we need to match by p-value
            let sortOrder = fixture.p_values.indices.sorted { fixture.p_values[$0] < fixture.p_values[$1] }
            let sortedExpectedAdj = sortOrder.map { fixture.expected_adjusted[$0] }
            let sortedExpectedSig = sortOrder.map { fixture.expected_significant[$0] }

            for (idx, result) in results.enumerated() {
                let tolerance = max(sortedExpectedAdj[idx] * 0.05, 0.001)
                let adjExpected = sortedExpectedAdj[idx]
                #expect(
                    abs(result.adjustedPValue - adjExpected) < tolerance,
                    Comment(rawValue: "BH adj mismatch \(fixture.name)[\(idx)]")
                )
                let sigExpected = sortedExpectedSig[idx]
                #expect(
                    result.isSignificant == sigExpected,
                    Comment(rawValue: "BH sig mismatch \(fixture.name)[\(idx)]")
                )
            }
        }
    }

    // MARK: - Unit Tests

    @Test func emptyInputReturnsEmpty() {
        let results = BenjaminiHochberg.correct([])
        #expect(results.isEmpty)
    }

    @Test func singleTestUnchanged() {
        let input = [makePairwiseResult(pValue: 0.03)]
        let results = BenjaminiHochberg.correct(input)

        #expect(results.count == 1)
        #expect(abs(results[0].adjustedPValue - 0.03) < 0.001)
        #expect(results[0].isSignificant)
    }

    @Test func adjustedPValuesCappedAtOne() {
        let input = [
            makePairwiseResult(pValue: 0.8, factor: "a"),
            makePairwiseResult(pValue: 0.9, factor: "b"),
        ]
        let results = BenjaminiHochberg.correct(input)

        for result in results {
            #expect(result.adjustedPValue <= 1.0)
        }
    }

    @Test func monotonicity() {
        let input = (0 ..< 10).map { i in
            makePairwiseResult(pValue: Double(i + 1) * 0.01, factor: "f\(i)")
        }
        let results = BenjaminiHochberg.correct(input)

        // Adjusted p-values should be monotonically non-decreasing
        for i in 1 ..< results.count {
            #expect(results[i].adjustedPValue >= results[i - 1].adjustedPValue)
        }
    }

    // MARK: - Helpers

    private func makePairwiseResult(pValue: Double, factor: String = "factor") -> PairwiseTestResult {
        PairwiseTestResult(
            targetVariable: "target",
            factorVariable: factor,
            lagDays: 0,
            pValue: pValue,
            effectSize: 0.3,
            effectMagnitude: .medium,
            testMethod: "spearman",
            sampleSize: 50,
            dataCompleteness: 0.8,
            meanHigh: nil,
            meanLow: nil
        )
    }
}

private final class BundleToken {}
