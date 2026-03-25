import SwiftUI

struct AddMealEntrySheet: View {
    let mealCategory: MealCategory
    let nutritionService: NutritionService
    let openFoodFactsService: OpenFoodFactsService
    let user: User
    let nutrientDefinitions: [NutrientDefinition]
    let date: Date
    let onMealAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var foodSearchViewModel: FoodSearchViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = foodSearchViewModel {
                    FoodSearchView(
                        viewModel: vm,
                        mealCategory: mealCategory,
                        nutritionService: nutritionService,
                        user: user,
                        date: date,
                        nutrientDefinitions: nutrientDefinitions,
                        onMealAdded: {
                            onMealAdded()
                            dismiss()
                        }
                    )
                } else {
                    ProgressView()
                        .onAppear { setupViewModel() }
                }
            }
            .navigationTitle("Add to \(mealCategory.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func setupViewModel() {
        foodSearchViewModel = FoodSearchViewModel(
            nutritionService: nutritionService,
            openFoodFactsService: openFoodFactsService,
            user: user,
            nutrientDefinitions: nutrientDefinitions
        )
    }
}
