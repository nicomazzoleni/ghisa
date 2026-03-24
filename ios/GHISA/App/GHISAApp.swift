import SwiftData
import SwiftUI

@main
struct GHISAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentRoot()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            User.self,
            Exercise.self,
            ExerciseFieldDefinition.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            WorkoutSetValue.self,
            WorkoutTemplate.self,
            WorkoutTemplateExercise.self,
            WorkoutTemplateFieldTarget.self,
            Flag.self,
            FlagAssignment.self,
            NutrientDefinition.self,
            FoodItem.self,
            FoodItemNutrient.self,
            Recipe.self,
            RecipeIngredient.self,
            MealCategory.self,
            MealEntry.self,
            MealTemplate.self,
            MealTemplateItem.self,
            NutritionTarget.self,
            DailyLog.self,
            DailyLogFieldDefinition.self,
            DailyLogValue.self,
            CorrelationResult.self,
        ])
    }
}
