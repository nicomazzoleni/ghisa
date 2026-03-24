@testable import GHISA
import Testing

struct NutritionTests {
    @Test func nutrientDefinitionDefaults() {
        let user = User()
        let nutrient = NutrientDefinition(
            user: user,
            name: "Protein",
            unit: "g",
            isDefault: true,
            sortOrder: 1,
            apiKey: "proteins"
        )
        #expect(nutrient.name == "Protein")
        #expect(nutrient.unit == "g")
        #expect(nutrient.isDefault == true)
        #expect(nutrient.isVisible == true)
        #expect(nutrient.apiKey == "proteins")
    }

    @Test func mealCategoryDefaults() {
        let user = User()
        let category = MealCategory(user: user, name: "Breakfast", sortOrder: 0, isDefault: true)
        #expect(category.name == "Breakfast")
        #expect(category.sortOrder == 0)
        #expect(category.isDefault == true)
    }

    @Test func foodItemDefaults() {
        let food = FoodItem(name: "Chicken Breast")
        #expect(food.name == "Chicken Breast")
        #expect(food.servingSizeG == 100)
        #expect(food.servingUnit == "g")
        #expect(food.isFavorite == false)
        #expect(food.user == nil)
    }
}
