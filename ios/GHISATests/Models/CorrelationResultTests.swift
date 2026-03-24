@testable import GHISA
import Testing

struct CorrelationResultTests {
    @Test func correlationResultCreation() {
        let user = User()
        let result = CorrelationResult(
            user: user,
            targetVariable: "squat_1rm",
            factorVariable: "sleep_hours",
            testMethod: "spearman",
            effectSize: 0.45,
            pValue: 0.01,
            sampleSize: 30,
            effectDescription: "More sleep is associated with higher squat 1RM",
            confidenceBadge: "strong",
            isSignificant: true,
            dataCompleteness: 0.85
        )
        #expect(result.targetVariable == "squat_1rm")
        #expect(result.factorVariable == "sleep_hours")
        #expect(result.isSignificant == true)
        #expect(result.confidenceBadge == "strong")
        #expect(result.lagDays == 0)
    }
}
