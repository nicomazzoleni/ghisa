import Foundation
import SwiftData

// MARK: - Nutrition Data Seeder

extension DataSeedService {
    // MARK: - Public API

    func hasSeededNutritionData() throws -> Bool {
        let names = NutritionSeedConfig.seededFoodNames
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                names.contains(food.name)
            }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }

    func clearNutritionData() throws {
        // Delete seeded food items (cascade deletes FoodItemNutrient rows)
        let names = NutritionSeedConfig.seededFoodNames
        let foodDescriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                names.contains(food.name)
            }
        )
        let foods = try modelContext.fetch(foodDescriptor)
        for food in foods {
            modelContext.delete(food)
        }

        // Delete orphaned meal entries (foodItem was nullified by cascade)
        let mealDescriptor = FetchDescriptor<MealEntry>()
        let meals = try modelContext.fetch(mealDescriptor)
        for meal in meals where meal.foodItem == nil && meal.recipe == nil {
            modelContext.delete(meal)
        }

        try modelContext.save()
    }

    @MainActor
    func seedNutritionData() async throws -> Int {
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try modelContext.fetch(userDescriptor).first else {
            throw AppError.validation(message: "No user found. Run initial seed first.")
        }

        // Fetch existing nutrient definitions (seeded by seedIfNeeded)
        let nutrientDescriptor = FetchDescriptor<NutrientDefinition>()
        let allNutrients = try modelContext.fetch(nutrientDescriptor)
        let nutrients = NutrientLookup(
            calories: allNutrients.first { $0.apiKey == "energy-kcal" },
            protein: allNutrients.first { $0.apiKey == "proteins" },
            carbs: allNutrients.first { $0.apiKey == "carbohydrates" },
            fat: allNutrients.first { $0.apiKey == "fat" }
        )

        // Fetch meal categories
        let categoryDescriptor = FetchDescriptor<MealCategory>()
        let allCategories = try modelContext.fetch(categoryDescriptor)
        let categories = CategoryLookup(
            breakfast: allCategories.first { $0.name == "Breakfast" },
            lunch: allCategories.first { $0.name == "Lunch" },
            dinner: allCategories.first { $0.name == "Dinner" },
            snack: allCategories.first { $0.name == "Snack" }
        )

        // Create food items
        let foodMap = createSeederFoodItems(for: user, nutrients: nutrients)

        // Generate 365 days of meals
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var mealCount = 0

        for dayOffset in 1 ... 365 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // ~2% chance to skip entire day (forgot to track)
            if Float.random(in: 0 ... 1) < 0.02 { continue }

            let weekday = calendar.component(.weekday, from: date)
            let isTrainingDay = weekday == 2 || weekday == 5 // Monday or Thursday
            let isWeekend = weekday == 1 || weekday == 7

            let targets = computeDailyTargets(isTrainingDay: isTrainingDay, isWeekend: isWeekend)
            mealCount += generateMealsForDay(
                date: date, user: user, categories: categories,
                foodMap: foodMap, targets: targets
            )

            if dayOffset % 30 == 0 { await Task.yield() }
        }

        try modelContext.save()
        return mealCount
    }

    // MARK: - Private Helpers

    private struct NutrientLookup {
        let calories: NutrientDefinition?
        let protein: NutrientDefinition?
        let carbs: NutrientDefinition?
        let fat: NutrientDefinition?
    }

    private struct CategoryLookup {
        let breakfast: MealCategory?
        let lunch: MealCategory?
        let dinner: MealCategory?
        let snack: MealCategory?
    }

    private struct MacroTargets {
        let kcal: Float
        let protein: Float
        let carbs: Float
        let fat: Float
    }

    private func createSeederFoodItems(
        for user: User,
        nutrients: NutrientLookup
    ) -> [String: FoodItem] {
        var foodMap: [String: FoodItem] = [:]

        for config in NutritionSeedConfig.foodConfigs {
            let food = FoodItem(
                user: user,
                name: config.name,
                servingSizeG: config.servingSizeG,
                servingUnit: config.servingUnit
            )
            modelContext.insert(food)

            if let cal = nutrients.calories {
                modelContext.insert(FoodItemNutrient(
                    foodItem: food, nutrientDefinition: cal, valuePerServing: config.kcal
                ))
            }
            if let prot = nutrients.protein {
                modelContext.insert(FoodItemNutrient(
                    foodItem: food, nutrientDefinition: prot, valuePerServing: config.protein
                ))
            }
            if let carb = nutrients.carbs {
                modelContext.insert(FoodItemNutrient(
                    foodItem: food, nutrientDefinition: carb, valuePerServing: config.carbs
                ))
            }
            if let fatDef = nutrients.fat {
                modelContext.insert(FoodItemNutrient(
                    foodItem: food, nutrientDefinition: fatDef, valuePerServing: config.fat
                ))
            }

            foodMap[config.name] = food
        }

        return foodMap
    }

    private func computeDailyTargets(isTrainingDay: Bool, isWeekend: Bool) -> MacroTargets {
        var kcal: Float = 2800
        var protein: Float = 180
        var carbs: Float = 350
        var fat: Float = 80

        if isTrainingDay {
            carbs *= 1.10
        }
        if isWeekend {
            kcal *= 1.15
            carbs *= 1.08
            fat *= 1.12
        }

        // Day-to-day noise ±10%
        kcal *= Float.random(in: 0.90 ... 1.10)
        protein *= Float.random(in: 0.90 ... 1.10)
        carbs *= Float.random(in: 0.90 ... 1.10)
        fat *= Float.random(in: 0.90 ... 1.10)

        return MacroTargets(kcal: kcal, protein: protein, carbs: carbs, fat: fat)
    }

    private func generateMealsForDay(
        date: Date, user: User, categories: CategoryLookup,
        foodMap: [String: FoodItem], targets: MacroTargets
    ) -> Int {
        let templates: [(NutritionSeedConfig.MealTemplate, String)] = [
            (pickTemplate(NutritionSeedConfig.breakfastTemplates), "breakfast"),
            (pickTemplate(NutritionSeedConfig.lunchTemplates), "lunch"),
            (pickTemplate(NutritionSeedConfig.dinnerTemplates), "dinner"),
            (pickTemplate(NutritionSeedConfig.snackTemplates), "snack"),
        ]

        let skipMeal: String? = Float.random(in: 0 ... 1) < 0.05
            ? (Float.random(in: 0 ... 1) < 0.6 ? "breakfast" : "snack") : nil

        let activeMeals = templates.filter { $0.1 != skipMeal }
        let baseKcal = activeMeals.reduce(Float(0)) { $0 + templateCalories($1.0) }
        let scale = baseKcal > 0 ? min(max(targets.kcal / baseKcal, 0.7), 1.4) : 1.0

        var count = 0
        for (template, slot) in activeMeals {
            guard let category = mealCategory(for: slot, from: categories) else { continue }
            let loggedAt = mealTime(for: slot, on: date)
            for item in template {
                guard let food = foodMap[item.foodName] else { continue }
                let qty = (item.servings * scale * 10).rounded() / 10
                let entry = MealEntry(user: user, date: date, mealCategory: category, quantity: qty, foodItem: food)
                entry.loggedAt = loggedAt
                modelContext.insert(entry)
                count += 1
            }
        }
        return count
    }

    private func pickTemplate(_ pool: [NutritionSeedConfig.MealTemplate]) -> NutritionSeedConfig.MealTemplate {
        pool[Int.random(in: 0 ..< pool.count)]
    }

    private func mealCategory(for slot: String, from categories: CategoryLookup) -> MealCategory? {
        switch slot {
            case "breakfast": categories.breakfast
            case "lunch": categories.lunch
            case "dinner": categories.dinner
            default: categories.snack
        }
    }

    private func mealTime(for slot: String, on date: Date) -> Date {
        let (hour, minute): (Int, Int) = switch slot {
            case "breakfast": (Int.random(in: 7 ... 8), Int.random(in: 0 ... 59))
            case "lunch": (Int.random(in: 12 ... 13), Int.random(in: 0 ... 30))
            case "dinner": (Int.random(in: 18 ... 20), Int.random(in: 0 ... 30))
            default: (Bool.random() ? Int.random(in: 15 ... 16) : Int.random(in: 21 ... 22), Int.random(in: 0 ... 59))
        }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private func templateCalories(_ template: NutritionSeedConfig.MealTemplate) -> Float {
        template.reduce(Float(0)) { total, item in
            let kcal = NutritionSeedConfig.foodConfigs.first { $0.name == item.foodName }?.kcal ?? 0
            return total + kcal * item.servings
        }
    }
}
