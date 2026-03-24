import SwiftUI

struct AddFieldView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var fieldType: String = "number"
    @State private var unit: String = ""
    @State private var selectOptionsText: String = ""

    let onSave: (String, String, String?, [String]?) -> Void

    private let fieldTypes = ["number", "text", "select", "toggle"]

    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if fieldType == "select" {
            return !parseSelectOptions().isEmpty
        }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Name
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Field Name")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Text.secondary)

                    TextField("e.g. RPE, Tempo, Grip", text: $name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.primary)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                }

                // Type Picker
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Type")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Text.secondary)

                    Picker("Type", selection: $fieldType) {
                        ForEach(fieldTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Unit (for number type)
                if fieldType == "number" {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Unit (optional)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Text.secondary)

                        TextField("e.g. kg, lbs, seconds", text: $unit)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.primary)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    }
                }

                // Select Options
                if fieldType == "select" {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Options (comma-separated)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Text.secondary)

                        TextField("e.g. wide, normal, close", text: $selectOptionsText)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.primary)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Background.base)
        .navigationTitle("Add Field")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Theme.Text.secondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { save() }
                    .foregroundStyle(isValid ? Theme.Accent.primary : Theme.Text.tertiary)
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let unitValue: String? = trimmedUnit.isEmpty ? nil : trimmedUnit
        let options: [String]? = fieldType == "select" ? parseSelectOptions() : nil

        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), fieldType, unitValue, options)
        dismiss()
    }

    private func parseSelectOptions() -> [String] {
        selectOptionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
