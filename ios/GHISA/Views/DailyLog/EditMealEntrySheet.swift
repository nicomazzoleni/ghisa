import SwiftUI

struct EditMealEntrySheet: View {
    let entry: MealEntry
    let nutrientDefinitions: [NutrientDefinition]
    let onSave: (Float) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Float
    @State private var quantityText: String

    init(entry: MealEntry, nutrientDefinitions: [NutrientDefinition], onSave: @escaping (Float) -> Void) {
        self.entry = entry
        self.nutrientDefinitions = nutrientDefinitions
        self.onSave = onSave
        self._quantity = State(initialValue: entry.quantity)
        let qty = entry.quantity
        self._quantityText = State(initialValue: qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(qty))
            : String(format: "%.1f", qty))
    }

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
            .navigationTitle("Edit Serving")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(quantity)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var foodHeader: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(entry.foodItem?.name ?? "Unknown Food")
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)

                if let brand = entry.foodItem?.brand, !brand.isEmpty {
                    Text(brand)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Text.tertiary)
                }

                if let food = entry.foodItem {
                    Text("Serving: \(food.servingUnit) (\(Int(food.servingSizeG))g)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Text.secondary)
                }
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
        let perServing = entry.foodItem?.nutrients
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
}
