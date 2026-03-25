import Foundation

enum AppConfig {
    static let appName = "GHISA"

    enum API {
        #if DEBUG
        // swiftlint:disable:next force_unwrapping
        static let baseURL = URL(string: "http://localhost:8000/api/v1")!
        #else
        // swiftlint:disable:next force_unwrapping
        static let baseURL = URL(string: "https://api.ghisa.app/api/v1")!
        #endif
    }

    enum HealthKit {
        /// Number of days to import on first HealthKit authorization
        static let historicalImportDays = 90
    }

    enum Correlation {
        /// Minimum matched data points for a correlation to be computed
        static let minimumSampleSize = 20
        /// Significance threshold (after BH correction)
        static let significanceThreshold: Double = 0.05
        /// Maximum lag days to test
        static let maximumLagDays = 7
    }

    enum OpenFoodFacts {
        // swiftlint:disable:next force_unwrapping
        static let baseURL = URL(string: "https://world.openfoodfacts.net")!
        static let pageSize = 25
    }

    enum Defaults {
        static let defaultUnitSystem = "metric"
        static let defaultMealCategories = ["Breakfast", "Lunch", "Dinner", "Snack"]
    }
}
