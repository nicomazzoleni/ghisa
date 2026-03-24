import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var servings: Int
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    @Relationship(deleteRule: .nullify, inverse: \MealEntry.recipe)
    var mealEntries: [MealEntry]

    @Relationship(deleteRule: .nullify, inverse: \MealTemplateItem.recipe)
    var mealTemplateItems: [MealTemplateItem]

    var createdAt: Date
    var updatedAt: Date

    init(user: User, name: String, servings: Int = 1) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.servings = servings
        self.ingredients = []
        self.mealEntries = []
        self.mealTemplateItems = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
