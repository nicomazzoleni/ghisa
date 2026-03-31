import Foundation

// MARK: - Confidence Badge

enum ConfidenceBadge: String {
    case strong = "Strong"
    case moderate = "Moderate"
    case earlyTrend = "Early trend"

    /// Compute confidence badge from effect magnitude, sample size, and data completeness.
    /// Matrix from CORRELATION_ENGINE.md §6.
    static func compute(
        effectMagnitude: EffectSizeMagnitude,
        sampleSize: Int,
        dataCompleteness: Double
    ) -> ConfidenceBadge {
        // Cap at "Early trend" if completeness is below 50%
        if dataCompleteness < 0.5 {
            return .earlyTrend
        }

        let sampleBucket: SampleBucket = if sampleSize >= 100 {
            .large
        } else if sampleSize >= 50 {
            .medium
        } else {
            .small
        }

        return matrix(effect: effectMagnitude, sample: sampleBucket)
    }

    // MARK: - Private

    private enum SampleBucket {
        case large // n >= 100
        case medium // 50 <= n < 100
        case small // 20 <= n < 50
    }

    ///                 n >= 100    50 <= n < 100    20 <= n < 50
    /// Large effect    Strong      Strong           Moderate
    /// Medium effect   Strong      Moderate         Early trend
    /// Small effect    Moderate    Early trend      Early trend
    private static func matrix(effect: EffectSizeMagnitude, sample: SampleBucket) -> ConfidenceBadge {
        switch (effect, sample) {
            case (.large, .large), (.large, .medium), (.medium, .large):
                .strong
            case (.large, .small), (.medium, .medium), (.small, .large):
                .moderate
            case (.medium, .small), (.small, .medium), (.small, .small):
                .earlyTrend
            // Negligible effect should not reach here (filtered by significance), but handle gracefully
            case (.negligible, _):
                .earlyTrend
        }
    }
}
