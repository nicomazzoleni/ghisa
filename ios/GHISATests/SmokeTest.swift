@testable import GHISA
import Testing

struct SmokeTest {
    @Test func appConfigExists() {
        #expect(AppConfig.appName == "GHISA")
        #expect(AppConfig.Correlation.minimumSampleSize == 20)
        #expect(AppConfig.Correlation.significanceThreshold == 0.05)
        #expect(AppConfig.Correlation.maximumLagDays == 7)
        #expect(AppConfig.HealthKit.historicalImportDays == 90)
        #expect(AppConfig.Defaults.defaultUnitSystem == "metric")
        #expect(AppConfig.Defaults.defaultMealCategories.count == 4)
    }
}
