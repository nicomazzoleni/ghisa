import Foundation
import SwiftData

@Model
final class NutrientDefinition {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var unit: String
    var isDefault: Bool
    var sortOrder: Int
    var isVisible: Bool
    var apiKey: String?

    @Relationship(deleteRule: .cascade, inverse: \FoodItemNutrient.nutrientDefinition)
    var foodItemNutrients: [FoodItemNutrient]

    @Relationship(deleteRule: .cascade, inverse: \NutritionTarget.nutrientDefinition)
    var nutritionTargets: [NutritionTarget]

    var createdAt: Date

    init(
        user: User,
        name: String,
        unit: String,
        isDefault: Bool = false,
        sortOrder: Int,
        isVisible: Bool = true,
        apiKey: String? = nil
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.unit = unit
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.isVisible = isVisible
        self.apiKey = apiKey
        self.foodItemNutrients = []
        self.nutritionTargets = []
        self.createdAt = Date()
    }
}
