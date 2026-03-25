import Foundation
import SwiftData

@Observable
final class NutritionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Meal Categories

    func fetchMealCategories(for user: User) -> [MealCategory] {
        let userId = user.id
        let descriptor = FetchDescriptor<MealCategory>(
            predicate: #Predicate<MealCategory> { category in
                category.user.id == userId
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Nutrient Definitions

    func fetchVisibleNutrientDefinitions(for user: User) -> [NutrientDefinition] {
        let userId = user.id
        let descriptor = FetchDescriptor<NutrientDefinition>(
            predicate: #Predicate<NutrientDefinition> { def in
                def.user.id == userId && def.isVisible
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchAllNutrientDefinitions(for user: User) -> [NutrientDefinition] {
        let userId = user.id
        let descriptor = FetchDescriptor<NutrientDefinition>(
            predicate: #Predicate<NutrientDefinition> { def in
                def.user.id == userId
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Food Items (Local Cache)

    func searchLocalFoods(query: String, user: User) -> [FoodItem] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let userId = user.id
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                food.user?.id == userId
            },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse), SortDescriptor(\.name)]
        )

        let allFoods = (try? modelContext.fetch(descriptor)) ?? []
        return allFoods.filter { food in
            food.name.lowercased().contains(trimmed)
                || (food.brand?.lowercased().contains(trimmed) ?? false)
        }
    }

    func fetchRecentFoods(user: User, limit: Int = 10) -> [FoodItem] {
        let userId = user.id
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                food.user?.id == userId && food.lastUsedAt != nil
            },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )

        let results = (try? modelContext.fetch(descriptor)) ?? []
        return Array(results.prefix(limit))
    }

    func fetchFavoriteFoods(user: User) -> [FoodItem] {
        let userId = user.id
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                food.user?.id == userId && food.isFavorite
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func cacheFood(
        from product: OpenFoodFactsProduct,
        user: User,
        nutrientDefinitions: [NutrientDefinition]
    ) -> FoodItem {
        // Deduplicate by externalId
        let code = product.code
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                food.externalId == code
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let servingSizeG = product.servingQuantity ?? 100
        let servingUnit = product.servingSize ?? "\(Int(servingSizeG))g"

        let food = FoodItem(user: user, name: product.displayName, servingSizeG: servingSizeG, servingUnit: servingUnit)
        food.externalId = product.code
        food.brand = product.displayBrand
        modelContext.insert(food)

        // Add nutrient values
        if let nutriments = product.nutriments {
            let perServing = nutriments.perServing(servingSizeG: servingSizeG)
            for definition in nutrientDefinitions {
                if let apiKey = definition.apiKey, let value = perServing[apiKey] {
                    let nutrient = FoodItemNutrient(
                        foodItem: food,
                        nutrientDefinition: definition,
                        valuePerServing: value
                    )
                    modelContext.insert(nutrient)
                }
            }
        }

        try? modelContext.save()
        return food
    }

    // swiftlint:disable:next function_parameter_count
    func createCustomFood(
        name: String,
        brand: String?,
        servingSizeG: Float,
        servingUnit: String,
        nutrientValues: [UUID: Float],
        nutrientDefinitions: [NutrientDefinition],
        user: User
    ) throws -> FoodItem {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AppError.validation(message: "Food name cannot be empty.")
        }
        guard servingSizeG > 0 else {
            throw AppError.validation(message: "Serving size must be greater than zero.")
        }

        let food = FoodItem(user: user, name: trimmedName, servingSizeG: servingSizeG, servingUnit: servingUnit)
        food.brand = brand?.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(food)

        for definition in nutrientDefinitions {
            if let value = nutrientValues[definition.id], value > 0 {
                let nutrient = FoodItemNutrient(
                    foodItem: food,
                    nutrientDefinition: definition,
                    valuePerServing: value
                )
                modelContext.insert(nutrient)
            }
        }

        try modelContext.save()
        return food
    }

    func toggleFavorite(_ food: FoodItem) {
        food.isFavorite.toggle()
        food.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Meal Entries

    func fetchMealEntries(for date: Date, user: User) -> [MealEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let userId = user.id
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { entry in
                entry.user.id == userId && entry.date >= startOfDay && entry.date < nextDay
            },
            sortBy: [SortDescriptor(\.loggedAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addMealEntry(
        user: User,
        date: Date,
        mealCategory: MealCategory,
        foodItem: FoodItem,
        quantity: Float
    ) throws -> MealEntry {
        guard quantity > 0 else {
            throw AppError.validation(message: "Quantity must be greater than zero.")
        }

        let startOfDay = Calendar.current.startOfDay(for: date)

        let entry = MealEntry(
            user: user,
            date: startOfDay,
            mealCategory: mealCategory,
            quantity: quantity,
            foodItem: foodItem
        )
        modelContext.insert(entry)

        foodItem.lastUsedAt = Date()

        try modelContext.save()
        return entry
    }

    func deleteMealEntry(_ entry: MealEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    func updateMealEntryQuantity(_ entry: MealEntry, quantity: Float) throws {
        guard quantity > 0 else {
            throw AppError.validation(message: "Quantity must be greater than zero.")
        }
        entry.quantity = quantity
        try modelContext.save()
    }

    // MARK: - Nutrition Calculations

    func calculateDailyTotals(
        entries: [MealEntry],
        nutrientDefinitions: [NutrientDefinition]
    ) -> [UUID: Float] {
        var totals: [UUID: Float] = [:]
        for definition in nutrientDefinitions {
            totals[definition.id] = 0
        }

        for entry in entries {
            guard let food = entry.foodItem else { continue }
            for nutrient in food.nutrients {
                let defId = nutrient.nutrientDefinition.id
                let value = nutrient.valuePerServing * entry.quantity
                totals[defId, default: 0] += value
            }
        }

        return totals
    }

    /// Groups meal entries by their meal category ID.
    func groupEntriesByCategory(
        _ entries: [MealEntry],
        categories: [MealCategory]
    ) -> [UUID: [MealEntry]] {
        var grouped: [UUID: [MealEntry]] = [:]
        for category in categories {
            grouped[category.id] = []
        }
        for entry in entries {
            if let catId = entry.mealCategory?.id {
                grouped[catId, default: []].append(entry)
            }
        }
        return grouped
    }
}
