import SwiftUI

struct MealEntryRow: View {
    let entry: MealEntry
    let nutrientDefinitions: [NutrientDefinition]

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(entry.foodItem?.name ?? "Unknown Food")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.primary)
                    .lineLimit(1)

                Text(servingText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
            }

            Spacer()

            Text(caloriesText)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Text.secondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var servingText: String {
        let qty = entry.quantity
        let unit = entry.foodItem?.servingUnit ?? "serving"
        if qty == 1 {
            return "1 \(unit)"
        }
        let formatted = qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(qty))
            : String(format: "%.1f", qty)
        return "\(formatted) × \(unit)"
    }

    private var caloriesText: String {
        guard let food = entry.foodItem else { return "" }
        let calDef = nutrientDefinitions.first { $0.name.lowercased() == "calories" }
        guard let calDef else { return "" }
        let calNutrient = food.nutrients.first { $0.nutrientDefinition.id == calDef.id }
        guard let value = calNutrient?.valuePerServing else { return "" }
        let total = value * entry.quantity
        return "\(Int(total)) kcal"
    }
}
