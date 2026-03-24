@testable import GHISA
import SwiftData
import Testing

struct DataSeedServiceTests {
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: User.self, Exercise.self, ExerciseFieldDefinition.self,
            WorkoutSetValue.self, WorkoutExercise.self, WorkoutSet.self,
            WorkoutTemplateExercise.self, WorkoutTemplateFieldTarget.self,
            Workout.self, FlagAssignment.self, Flag.self,
            WorkoutTemplate.self, NutrientDefinition.self,
            FoodItem.self, FoodItemNutrient.self, Recipe.self,
            RecipeIngredient.self, MealCategory.self, MealEntry.self,
            MealTemplate.self, MealTemplateItem.self, NutritionTarget.self,
            DailyLog.self, DailyLogFieldDefinition.self, DailyLogValue.self,
            CorrelationResult.self,
            configurations: config
        )
        return ModelContext(container)
    }

    @Test func seedCreatesDefaultData() throws {
        let context = try makeContext()
        let service = DataSeedService(modelContext: context)
        try service.seedIfNeeded()

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)

        let categories = try context.fetch(FetchDescriptor<MealCategory>())
        #expect(categories.count == 4)

        let sortedCategories = categories.sorted { $0.sortOrder < $1.sortOrder }
        #expect(sortedCategories[0].name == "Breakfast")
        #expect(sortedCategories[1].name == "Lunch")
        #expect(sortedCategories[2].name == "Dinner")
        #expect(sortedCategories[3].name == "Snack")

        let nutrients = try context.fetch(FetchDescriptor<NutrientDefinition>())
        #expect(nutrients.count == 4)

        let sortedNutrients = nutrients.sorted { $0.sortOrder < $1.sortOrder }
        #expect(sortedNutrients[0].name == "Calories")
        #expect(sortedNutrients[0].apiKey == "energy-kcal")
        #expect(sortedNutrients[1].name == "Protein")
        #expect(sortedNutrients[1].apiKey == "proteins")

        let fields = try context.fetch(FetchDescriptor<DailyLogFieldDefinition>())
        #expect(fields.isEmpty)
    }

    @Test func seedIsIdempotent() throws {
        let context = try makeContext()
        let service = DataSeedService(modelContext: context)
        try service.seedIfNeeded()
        try service.seedIfNeeded()

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
    }
}
