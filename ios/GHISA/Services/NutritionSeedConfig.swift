import Foundation

enum NutritionSeedConfig {
    struct FoodConfig {
        let name: String
        let servingSizeG: Float
        let servingUnit: String
        let kcal: Float // per serving
        let protein: Float
        let carbs: Float
        let fat: Float
    }

    static let seededFoodNames = foodConfigs.map(\.name)

    /// All values are per serving (servingSizeG)
    static let foodConfigs: [FoodConfig] = [
        // Proteins
        FoodConfig(
            name: "Chicken Breast",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 165,
            protein: 31,
            carbs: 0,
            fat: 3.6
        ),
        FoodConfig(name: "Eggs", servingSizeG: 100, servingUnit: "g", kcal: 155, protein: 13, carbs: 1.1, fat: 11),
        FoodConfig(
            name: "Greek Yogurt",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 59,
            protein: 10,
            carbs: 3.6,
            fat: 0.4
        ),
        FoodConfig(
            name: "Whey Protein",
            servingSizeG: 30,
            servingUnit: "scoop",
            kcal: 120,
            protein: 24,
            carbs: 3,
            fat: 1
        ),
        FoodConfig(name: "Salmon", servingSizeG: 100, servingUnit: "g", kcal: 208, protein: 20, carbs: 0, fat: 13),
        FoodConfig(
            name: "Ground Beef 90/10",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 176,
            protein: 20,
            carbs: 0,
            fat: 10
        ),
        // Carbs
        FoodConfig(
            name: "White Rice (cooked)",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 130,
            protein: 2.7,
            carbs: 28,
            fat: 0.3
        ),
        FoodConfig(
            name: "Oats (dry)",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 389,
            protein: 17,
            carbs: 66,
            fat: 7
        ),
        FoodConfig(
            name: "Banana",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 89,
            protein: 1.1,
            carbs: 23,
            fat: 0.3
        ),
        FoodConfig(
            name: "Sweet Potato",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 86,
            protein: 1.6,
            carbs: 20,
            fat: 0.1
        ),
        FoodConfig(
            name: "Whole Wheat Bread",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 247,
            protein: 13,
            carbs: 41,
            fat: 3.4
        ),
        FoodConfig(
            name: "Pasta (cooked)",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 131,
            protein: 5,
            carbs: 25,
            fat: 1.1
        ),
        // Fats
        FoodConfig(
            name: "Olive Oil",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 884,
            protein: 0,
            carbs: 0,
            fat: 100
        ),
        FoodConfig(
            name: "Peanut Butter",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 588,
            protein: 25,
            carbs: 20,
            fat: 50
        ),
        FoodConfig(
            name: "Almonds",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 579,
            protein: 21,
            carbs: 22,
            fat: 50
        ),
        FoodConfig(name: "Avocado", servingSizeG: 100, servingUnit: "g", kcal: 160, protein: 2, carbs: 9, fat: 15),
        // Dairy & Other
        FoodConfig(
            name: "Whole Milk",
            servingSizeG: 100,
            servingUnit: "ml",
            kcal: 61,
            protein: 3.2,
            carbs: 4.8,
            fat: 3.3
        ),
        FoodConfig(
            name: "Cheese",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 403,
            protein: 25,
            carbs: 1.3,
            fat: 33
        ),
        FoodConfig(
            name: "Mixed Vegetables",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 65,
            protein: 3,
            carbs: 13,
            fat: 0.3
        ),
        FoodConfig(name: "Apple", servingSizeG: 100, servingUnit: "g", kcal: 52, protein: 0.3, carbs: 14, fat: 0.2),
        FoodConfig(
            name: "Rice Cakes",
            servingSizeG: 100,
            servingUnit: "g",
            kcal: 387,
            protein: 8,
            carbs: 81,
            fat: 2.8
        ),
        FoodConfig(name: "Honey", servingSizeG: 100, servingUnit: "g", kcal: 304, protein: 0.3, carbs: 82, fat: 0),
        FoodConfig(
            name: "Protein Bar",
            servingSizeG: 60,
            servingUnit: "bar",
            kcal: 200,
            protein: 20,
            carbs: 22,
            fat: 7
        ),
    ]

    // MARK: - Meal Templates

    struct MealItem {
        let foodName: String
        let servings: Float // number of servingSizeG portions
    }

    typealias MealTemplate = [MealItem]

    static let breakfastTemplates: [MealTemplate] = [
        [
            MealItem(foodName: "Oats (dry)", servings: 0.8),
            MealItem(foodName: "Banana", servings: 1.2),
            MealItem(foodName: "Whole Milk", servings: 2.0),
            MealItem(foodName: "Honey", servings: 0.15),
        ],
        [
            MealItem(foodName: "Eggs", servings: 2.0),
            MealItem(foodName: "Whole Wheat Bread", servings: 0.8),
            MealItem(foodName: "Peanut Butter", servings: 0.2),
        ],
        [
            MealItem(foodName: "Greek Yogurt", servings: 2.5),
            MealItem(foodName: "Oats (dry)", servings: 0.5),
            MealItem(foodName: "Banana", servings: 1.0),
            MealItem(foodName: "Honey", servings: 0.1),
        ],
        [
            MealItem(foodName: "Eggs", servings: 1.5),
            MealItem(foodName: "Cheese", servings: 0.3),
            MealItem(foodName: "Whole Wheat Bread", servings: 1.0),
            MealItem(foodName: "Banana", servings: 1.0),
        ],
    ]

    static let lunchTemplates: [MealTemplate] = [
        [
            MealItem(foodName: "Chicken Breast", servings: 1.8),
            MealItem(foodName: "White Rice (cooked)", servings: 2.5),
            MealItem(foodName: "Mixed Vegetables", servings: 1.5),
            MealItem(foodName: "Olive Oil", servings: 0.1),
        ],
        [
            MealItem(foodName: "Salmon", servings: 1.5),
            MealItem(foodName: "Sweet Potato", servings: 2.5),
            MealItem(foodName: "Mixed Vegetables", servings: 1.5),
        ],
        [
            MealItem(foodName: "Ground Beef 90/10", servings: 1.5),
            MealItem(foodName: "Pasta (cooked)", servings: 2.5),
            MealItem(foodName: "Olive Oil", servings: 0.1),
            MealItem(foodName: "Mixed Vegetables", servings: 1.0),
        ],
        [
            MealItem(foodName: "Chicken Breast", servings: 2.0),
            MealItem(foodName: "Sweet Potato", servings: 2.0),
            MealItem(foodName: "Avocado", servings: 0.8),
        ],
        [
            MealItem(foodName: "Ground Beef 90/10", servings: 1.8),
            MealItem(foodName: "White Rice (cooked)", servings: 2.0),
            MealItem(foodName: "Cheese", servings: 0.3),
            MealItem(foodName: "Mixed Vegetables", servings: 1.0),
        ],
    ]

    static let dinnerTemplates: [MealTemplate] = [
        [
            MealItem(foodName: "Salmon", servings: 2.0),
            MealItem(foodName: "White Rice (cooked)", servings: 2.0),
            MealItem(foodName: "Mixed Vegetables", servings: 1.5),
        ],
        [
            MealItem(foodName: "Chicken Breast", servings: 2.0),
            MealItem(foodName: "Pasta (cooked)", servings: 2.5),
            MealItem(foodName: "Olive Oil", servings: 0.1),
            MealItem(foodName: "Mixed Vegetables", servings: 1.5),
        ],
        [
            MealItem(foodName: "Ground Beef 90/10", servings: 2.0),
            MealItem(foodName: "Sweet Potato", servings: 2.5),
            MealItem(foodName: "Mixed Vegetables", servings: 1.5),
            MealItem(foodName: "Olive Oil", servings: 0.1),
        ],
        [
            MealItem(foodName: "Chicken Breast", servings: 1.8),
            MealItem(foodName: "White Rice (cooked)", servings: 2.5),
            MealItem(foodName: "Avocado", servings: 0.7),
            MealItem(foodName: "Mixed Vegetables", servings: 1.0),
        ],
        [
            MealItem(foodName: "Salmon", servings: 1.5),
            MealItem(foodName: "Pasta (cooked)", servings: 2.0),
            MealItem(foodName: "Mixed Vegetables", servings: 1.5),
            MealItem(foodName: "Cheese", servings: 0.3),
        ],
    ]

    static let snackTemplates: [MealTemplate] = [
        [
            MealItem(foodName: "Whey Protein", servings: 1.0),
            MealItem(foodName: "Banana", servings: 1.0),
        ],
        [
            MealItem(foodName: "Greek Yogurt", servings: 2.0),
            MealItem(foodName: "Almonds", servings: 0.3),
        ],
        [
            MealItem(foodName: "Protein Bar", servings: 1.0),
            MealItem(foodName: "Apple", servings: 1.5),
        ],
        [
            MealItem(foodName: "Rice Cakes", servings: 0.3),
            MealItem(foodName: "Peanut Butter", servings: 0.2),
        ],
        [
            MealItem(foodName: "Whey Protein", servings: 1.0),
            MealItem(foodName: "Whole Milk", servings: 2.0),
            MealItem(foodName: "Peanut Butter", servings: 0.15),
        ],
    ]
}
