import SwiftUI

struct CustomFieldRow: View {
    let field: DailyLogFieldDefinition
    let value: DailyLogValue?
    let onUpdate: (Float?, String?, Bool?) -> Void

    @State private var numberText: String = ""
    @State private var textValue: String = ""
    @State private var toggleValue: Bool = false
    @State private var hasInitialized = false

    var body: some View {
        HStack {
            Text(field.name)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)

            Spacer()

            fieldInput
        }
        .onAppear {
            guard !hasInitialized else { return }
            hasInitialized = true
            if let value {
                numberText = value.valueNumber.map { formatNumber($0) } ?? ""
                textValue = value.valueText ?? ""
                toggleValue = value.valueToggle ?? false
            }
        }
    }

    @ViewBuilder
    private var fieldInput: some View {
        switch field.fieldType {
            case "number":
                HStack(spacing: Theme.Spacing.xs) {
                    TextField("0", text: $numberText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                        .foregroundStyle(Theme.Text.primary)
                        .onChange(of: numberText) { _, newValue in
                            let number = Float(newValue)
                            onUpdate(number, nil, nil)
                        }

                    if let unit = field.unit, !unit.isEmpty {
                        Text(unit)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.secondary)
                    }
                }

            case "text":
                TextField("Enter value", text: $textValue)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 140)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Background.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    .foregroundStyle(Theme.Text.primary)
                    .onChange(of: textValue) { _, newValue in
                        onUpdate(nil, newValue.isEmpty ? nil : newValue, nil)
                    }

            case "toggle":
                Toggle("", isOn: $toggleValue)
                    .labelsHidden()
                    .tint(Theme.Accent.primary)
                    .onChange(of: toggleValue) { _, newValue in
                        onUpdate(nil, nil, newValue)
                    }

            default:
                EmptyView()
        }
    }

    private func formatNumber(_ value: Float) -> String {
        if value == Float(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
