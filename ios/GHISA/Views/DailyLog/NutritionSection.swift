import SwiftUI

struct NutritionSection: View {
    let viewModel: DailyLogViewModel

    @State private var entryToEdit: MealEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader
            macroSummary
            mealCategoryCards
        }
        .sheet(item: $entryToEdit) { entry in
            EditMealEntrySheet(
                entry: entry,
                nutrientDefinitions: viewModel.nutrientDefinitions
            ) { newQuantity in
                viewModel.updateMealEntryQuantity(entry, quantity: newQuantity)
            }
        }
    }

    private var sectionHeader: some View {
        Text("Nutrition")
            .font(Theme.Typography.sectionHeader)
            .foregroundStyle(Theme.Text.primary)
    }

    private var macroSummary: some View {
        CardView {
            HStack {
                if viewModel.nutritionSummaryText.isEmpty {
                    Text("No data yet")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.tertiary)
                } else {
                    Text(viewModel.nutritionSummaryText)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Text.secondary)
                }
                Spacer()
            }
        }
    }

    private var mealCategoryCards: some View {
        ForEach(viewModel.mealCategories, id: \.id) { category in
            MealCategoryCard(
                category: category,
                entries: viewModel.mealEntriesByCategory[category.id] ?? [],
                nutrientDefinitions: viewModel.nutrientDefinitions,
                onAddTapped: {
                    viewModel.openAddMealSheet(for: category)
                },
                onDelete: { entry in
                    viewModel.deleteMealEntry(entry)
                },
                onEdit: { entry in
                    entryToEdit = entry
                }
            )
        }
    }
}
