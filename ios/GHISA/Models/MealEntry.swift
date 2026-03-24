import Foundation
import SwiftData

@Model
final class MealEntry {
    @Attribute(.unique) var id: UUID
    var user: User
    var date: Date
    var mealCategory: MealCategory?
    var foodItem: FoodItem?
    var recipe: Recipe?
    var quantity: Float
    var loggedAt: Date
    var notes: String?
    var createdAt: Date

    init(
        user: User,
        date: Date,
        mealCategory: MealCategory,
        quantity: Float = 1,
        foodItem: FoodItem? = nil,
        recipe: Recipe? = nil
    ) {
        self.id = UUID()
        self.user = user
        self.date = date
        self.mealCategory = mealCategory
        self.foodItem = foodItem
        self.recipe = recipe
        self.quantity = quantity
        self.loggedAt = Date()
        self.createdAt = Date()
    }
}
