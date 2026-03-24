@testable import GHISA
import SwiftData

enum TestModelContainer {
    static func makeContext() throws -> (ModelContext, User) {
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
        let context = ModelContext(container)
        let user = User()
        context.insert(user)
        return (context, user)
    }
}
