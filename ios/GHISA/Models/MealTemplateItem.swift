import Foundation
import SwiftData

@Model
final class MealTemplateItem {
    @Attribute(.unique) var id: UUID
    var mealTemplate: MealTemplate
    var foodItem: FoodItem?
    var recipe: Recipe?
    var quantity: Float
    var sortOrder: Int

    init(
        mealTemplate: MealTemplate,
        quantity: Float = 1,
        sortOrder: Int,
        foodItem: FoodItem? = nil,
        recipe: Recipe? = nil
    ) {
        self.id = UUID()
        self.mealTemplate = mealTemplate
        self.foodItem = foodItem
        self.recipe = recipe
        self.quantity = quantity
        self.sortOrder = sortOrder
    }
}
