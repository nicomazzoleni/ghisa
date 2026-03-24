import SwiftUI

struct FieldValueInput: View {
    let fieldDefinition: ExerciseFieldDefinition
    let value: WorkoutSetValue
    let onUpdate: (Float?, String?, Bool?) -> Void

    @State private var textInput: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        switch fieldDefinition.fieldType {
            case "number":
                numberInput
            case "text":
                textFieldInput
            case "select":
                selectInput
            case "toggle":
                toggleInput
            default:
                Text("?")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
        }
    }

    private var numberInput: some View {
        TextField(
            fieldDefinition.unit ?? "#",
            text: $textInput
        )
        .keyboardType(.decimalPad)
        .textFieldStyle(.plain)
        .font(Theme.Typography.body)
        .foregroundStyle(Theme.Text.primary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Background.elevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        .frame(minWidth: 56)
        .focused($isFocused)
        .onAppear {
            if let num = value.valueNumber {
                textInput = formatNumber(num)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                let num = Float(textInput)
                onUpdate(num, nil, nil)
            }
        }
    }

    private var textFieldInput: some View {
        TextField("...", text: $textInput)
            .textFieldStyle(.plain)
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Text.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
            .frame(minWidth: 56)
            .focused($isFocused)
            .onAppear {
                textInput = value.valueText ?? ""
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    onUpdate(nil, trimmed.isEmpty ? nil : trimmed, nil)
                }
            }
    }

    private var selectInput: some View {
        Menu {
            ForEach(fieldDefinition.selectOptions ?? [], id: \.self) { option in
                Button(option) {
                    onUpdate(nil, option, nil)
                }
            }
            if value.valueText != nil {
                Divider()
                Button("Clear", role: .destructive) {
                    onUpdate(nil, nil, nil)
                }
            }
        } label: {
            Text(value.valueText ?? "Select")
                .font(Theme.Typography.body)
                .foregroundStyle(value.valueText != nil ? Theme.Text.primary : Theme.Text.tertiary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        }
    }

    private var toggleInput: some View {
        Button {
            let current = value.valueToggle ?? false
            onUpdate(nil, nil, !current)
        } label: {
            Image(systemName: (value.valueToggle ?? false) ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle((value.valueToggle ?? false) ? Theme.Accent.primary : Theme.Text.tertiary)
        }
        .buttonStyle(.plain)
    }

    private func formatNumber(_ num: Float) -> String {
        if num == num.rounded(), num < 10000 {
            return String(format: "%.0f", num)
        }
        return String(format: "%.1f", num)
    }
}
