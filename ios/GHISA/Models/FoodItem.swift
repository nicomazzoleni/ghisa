import Foundation
import SwiftData

@Model
final class FoodItem {
    @Attribute(.unique) var id: UUID
    var user: User?
    var externalId: String?
    var barcode: String?
    var name: String
    var brand: String?
    var servingSizeG: Float
    var servingUnit: String
    var isFavorite: Bool
    var lastUsedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \FoodItemNutrient.foodItem)
    var nutrients: [FoodItemNutrient]

    @Relationship(deleteRule: .nullify, inverse: \RecipeIngredient.foodItem)
    var recipeIngredients: [RecipeIngredient]

    @Relationship(deleteRule: .nullify, inverse: \MealEntry.foodItem)
    var mealEntries: [MealEntry]

    @Relationship(deleteRule: .nullify, inverse: \MealTemplateItem.foodItem)
    var mealTemplateItems: [MealTemplateItem]

    var createdAt: Date
    var updatedAt: Date

    init(
        user: User? = nil,
        name: String,
        servingSizeG: Float = 100,
        servingUnit: String = "g"
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.servingSizeG = servingSizeG
        self.servingUnit = servingUnit
        self.isFavorite = false
        self.nutrients = []
        self.recipeIngredients = []
        self.mealEntries = []
        self.mealTemplateItems = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
