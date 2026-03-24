import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var recipe: Recipe
    var foodItem: FoodItem?
    var quantity: Float
    var sortOrder: Int

    init(
        recipe: Recipe,
        foodItem: FoodItem,
        quantity: Float,
        sortOrder: Int
    ) {
        self.id = UUID()
        self.recipe = recipe
        self.foodItem = foodItem
        self.quantity = quantity
        self.sortOrder = sortOrder
    }
}
