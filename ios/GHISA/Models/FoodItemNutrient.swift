import Foundation
import SwiftData

@Model
final class FoodItemNutrient {
    @Attribute(.unique) var id: UUID
    var foodItem: FoodItem
    var nutrientDefinition: NutrientDefinition
    var valuePerServing: Float

    init(
        foodItem: FoodItem,
        nutrientDefinition: NutrientDefinition,
        valuePerServing: Float
    ) {
        self.id = UUID()
        self.foodItem = foodItem
        self.nutrientDefinition = nutrientDefinition
        self.valuePerServing = valuePerServing
    }
}
