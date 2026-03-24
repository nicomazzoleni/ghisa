import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String?
    var age: Int?
    var gender: String?
    var heightCm: Float?
    var weightKg: Float?
    var unitSystem: String

    @Relationship(deleteRule: .cascade, inverse: \Exercise.user)
    var exercises: [Exercise]

    @Relationship(deleteRule: .cascade, inverse: \Workout.user)
    var workouts: [Workout]

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.user)
    var workoutTemplates: [WorkoutTemplate]

    @Relationship(deleteRule: .cascade, inverse: \Flag.user)
    var flags: [Flag]

    @Relationship(deleteRule: .cascade, inverse: \NutrientDefinition.user)
    var nutrientDefinitions: [NutrientDefinition]

    @Relationship(deleteRule: .cascade, inverse: \FoodItem.user)
    var foodItems: [FoodItem]

    @Relationship(deleteRule: .cascade, inverse: \Recipe.user)
    var recipes: [Recipe]

    @Relationship(deleteRule: .cascade, inverse: \MealCategory.user)
    var mealCategories: [MealCategory]

    @Relationship(deleteRule: .cascade, inverse: \MealEntry.user)
    var mealEntries: [MealEntry]

    @Relationship(deleteRule: .cascade, inverse: \MealTemplate.user)
    var mealTemplates: [MealTemplate]

    @Relationship(deleteRule: .cascade, inverse: \NutritionTarget.user)
    var nutritionTargets: [NutritionTarget]

    @Relationship(deleteRule: .cascade, inverse: \DailyLog.user)
    var dailyLogs: [DailyLog]

    @Relationship(deleteRule: .cascade, inverse: \DailyLogFieldDefinition.user)
    var dailyLogFieldDefinitions: [DailyLogFieldDefinition]

    @Relationship(deleteRule: .cascade, inverse: \CorrelationResult.user)
    var correlationResults: [CorrelationResult]

    var createdAt: Date
    var updatedAt: Date

    init(
        name: String? = nil,
        unitSystem: String = AppConfig.Defaults.defaultUnitSystem
    ) {
        self.id = UUID()
        self.name = name
        self.unitSystem = unitSystem
        self.exercises = []
        self.workouts = []
        self.workoutTemplates = []
        self.flags = []
        self.nutrientDefinitions = []
        self.foodItems = []
        self.recipes = []
        self.mealCategories = []
        self.mealEntries = []
        self.mealTemplates = []
        self.nutritionTargets = []
        self.dailyLogs = []
        self.dailyLogFieldDefinitions = []
        self.correlationResults = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
