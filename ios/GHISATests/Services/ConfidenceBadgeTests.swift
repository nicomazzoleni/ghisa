@testable import GHISA
import Testing

struct ConfidenceBadgeTests {
    @Test func matrixLargeEffectLargeSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .large, sampleSize: 150, dataCompleteness: 0.8)
        #expect(badge == .strong)
    }

    @Test func matrixLargeEffectMediumSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .large, sampleSize: 75, dataCompleteness: 0.8)
        #expect(badge == .strong)
    }

    @Test func matrixLargeEffectSmallSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .large, sampleSize: 30, dataCompleteness: 0.8)
        #expect(badge == .moderate)
    }

    @Test func matrixMediumEffectLargeSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .medium, sampleSize: 150, dataCompleteness: 0.8)
        #expect(badge == .strong)
    }

    @Test func matrixMediumEffectMediumSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .medium, sampleSize: 75, dataCompleteness: 0.8)
        #expect(badge == .moderate)
    }

    @Test func matrixMediumEffectSmallSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .medium, sampleSize: 30, dataCompleteness: 0.8)
        #expect(badge == .earlyTrend)
    }

    @Test func matrixSmallEffectLargeSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .small, sampleSize: 150, dataCompleteness: 0.8)
        #expect(badge == .moderate)
    }

    @Test func matrixSmallEffectSmallSample() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .small, sampleSize: 30, dataCompleteness: 0.8)
        #expect(badge == .earlyTrend)
    }

    @Test func lowCompletenessCapsBadge() {
        // Even with large effect and large sample, low completeness → earlyTrend
        let badge = ConfidenceBadge.compute(effectMagnitude: .large, sampleSize: 200, dataCompleteness: 0.3)
        #expect(badge == .earlyTrend)
    }

    @Test func negligibleEffectAlwaysEarlyTrend() {
        let badge = ConfidenceBadge.compute(effectMagnitude: .negligible, sampleSize: 200, dataCompleteness: 0.9)
        #expect(badge == .earlyTrend)
    }
}
