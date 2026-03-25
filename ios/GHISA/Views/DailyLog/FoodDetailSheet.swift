import SwiftUI

struct FoodDetailSheet: View {
    let food: FoodItem
    let mealCategory: MealCategory
    let nutrientDefinitions: [NutrientDefinition]
    let nutritionService: NutritionService
    let user: User
    let date: Date
    let onMealAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Float = 1.0
    @State private var quantityText = "1"
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    foodHeader
                    servingPicker
                    nutritionPreview
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Background.base)
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var foodHeader: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(food.name)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)

                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Text.tertiary)
                }

                Text("Serving: \(food.servingUnit) (\(Int(food.servingSizeG))g)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var servingPicker: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Servings")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Text.primary)

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        adjustQuantity(by: -0.5)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(quantity > 0.5 ? Theme.Accent.primary : Theme.Text.tertiary)
                    }
                    .disabled(quantity <= 0.5)

                    TextField("1", text: $quantityText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(Theme.Typography.sectionHeader)
                        .foregroundStyle(Theme.Text.primary)
                        .frame(width: 80)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                        .onChange(of: quantityText) {
                            if let parsed = Float(quantityText), parsed > 0 {
                                quantity = parsed
                            }
                        }

                    Button {
                        adjustQuantity(by: 0.5)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.Accent.primary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var nutritionPreview: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Nutrition")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Text.primary)

                ForEach(nutrientDefinitions, id: \.id) { def in
                    let value = nutrientValue(for: def)
                    HStack {
                        Text(def.name)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.secondary)
                        Spacer()
                        Text("\(Int(value)) \(def.unit)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Text.primary)
                    }
                }
            }
        }
    }

    private func nutrientValue(for def: NutrientDefinition) -> Float {
        let perServing = food.nutrients
            .first { $0.nutrientDefinition.id == def.id }?
            .valuePerServing ?? 0
        return perServing * quantity
    }

    private func adjustQuantity(by delta: Float) {
        let newQty = max(0.5, quantity + delta)
        quantity = newQty
        quantityText = newQty.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(newQty))
            : String(format: "%.1f", newQty)
    }

    private func addEntry() {
        do {
            _ = try nutritionService.addMealEntry(
                user: user,
                date: date,
                mealCategory: mealCategory,
                foodItem: food,
                quantity: quantity
            )
            onMealAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
