import SwiftUI

struct CreateCustomFoodView: View {
    let nutritionService: NutritionService
    let nutrientDefinitions: [NutrientDefinition]
    let user: User
    let onFoodCreated: (FoodItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var servingSizeText = "100"
    @State private var servingUnit = "g"
    @State private var nutrientTexts: [UUID: String] = [:]
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    foodInfoSection
                    servingSection
                    nutrientsSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Background.base)
            .navigationTitle("Create Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFood() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private var foodInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Food Info")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Text.primary)

            CardView {
                VStack(spacing: Theme.Spacing.md) {
                    inputField("Name", text: $name, placeholder: "e.g. Chicken Breast")
                    inputField("Brand (optional)", text: $brand, placeholder: "e.g. Generic")
                }
            }
        }
    }

    private var servingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Serving Size")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Text.primary)

            CardView {
                HStack(spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Size (g)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.secondary)
                        TextField("100", text: $servingSizeText)
                            .keyboardType(.decimalPad)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.primary)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Unit label")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.secondary)
                        TextField("g", text: $servingUnit)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.primary)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    }
                }
            }
        }
    }

    private var nutrientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Nutrition per serving")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Text.primary)

            CardView {
                VStack(spacing: Theme.Spacing.md) {
                    ForEach(nutrientDefinitions, id: \.id) { def in
                        HStack(spacing: Theme.Spacing.sm) {
                            Text(def.name)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Text.secondary)
                                .frame(width: 80, alignment: .leading)

                            TextField("0", text: nutrientBinding(for: def.id))
                                .keyboardType(.decimalPad)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Text.primary)
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Background.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))

                            Text(def.unit)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Text.tertiary)
                                .frame(width: 32, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private func inputField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.secondary)
            TextField(placeholder, text: text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        }
    }

    private func nutrientBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { nutrientTexts[id] ?? "" },
            set: { nutrientTexts[id] = $0 }
        )
    }

    private func saveFood() {
        let servingSizeG = Float(servingSizeText) ?? 0

        var nutrientValues: [UUID: Float] = [:]
        for (id, text) in nutrientTexts {
            if let value = Float(text) {
                nutrientValues[id] = value
            }
        }

        do {
            let food = try nutritionService.createCustomFood(
                name: name,
                brand: brand.isEmpty ? nil : brand,
                servingSizeG: servingSizeG,
                servingUnit: servingUnit.isEmpty ? "g" : servingUnit,
                nutrientValues: nutrientValues,
                nutrientDefinitions: nutrientDefinitions,
                user: user
            )
            dismiss()
            onFoodCreated(food)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
