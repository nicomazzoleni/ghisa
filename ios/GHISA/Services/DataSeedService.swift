import Foundation
import SwiftData

@Observable
final class DataSeedService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func seedIfNeeded() throws {
        let descriptor = FetchDescriptor<User>()
        let existingUsers = try modelContext.fetch(descriptor)

        if !existingUsers.isEmpty { return }

        let user = User()
        modelContext.insert(user)

        seedMealCategories(for: user)
        seedNutrientDefinitions(for: user)
        seedDailyLogFieldDefinitions(for: user)

        try modelContext.save()
    }

    private func seedMealCategories(for user: User) {
        for (index, name) in AppConfig.Defaults.defaultMealCategories.enumerated() {
            let category = MealCategory(
                user: user,
                name: name,
                sortOrder: index,
                isDefault: true
            )
            modelContext.insert(category)
        }
    }

    private struct DefaultNutrient {
        let name: String
        let unit: String
        let apiKey: String
    }

    private static let defaultNutrients: [DefaultNutrient] = [
        DefaultNutrient(name: "Calories", unit: "kcal", apiKey: "energy-kcal"),
        DefaultNutrient(name: "Protein", unit: "g", apiKey: "proteins"),
        DefaultNutrient(name: "Carbs", unit: "g", apiKey: "carbohydrates"),
        DefaultNutrient(name: "Fat", unit: "g", apiKey: "fat"),
    ]

    private func seedNutrientDefinitions(for user: User) {
        for (index, nutrient) in Self.defaultNutrients.enumerated() {
            let definition = NutrientDefinition(
                user: user,
                name: nutrient.name,
                unit: nutrient.unit,
                isDefault: true,
                sortOrder: index,
                isVisible: true,
                apiKey: nutrient.apiKey
            )
            modelContext.insert(definition)
        }
    }

    private func seedDailyLogFieldDefinitions(for user: User) {
        // No default fields — users add their own custom fields
    }
}
