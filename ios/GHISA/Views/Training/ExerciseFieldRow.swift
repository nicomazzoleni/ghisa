import SwiftUI

struct ExerciseFieldRow: View {
    let field: ExerciseFieldDefinition
    let onToggleActive: () -> Void

    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(field.name)
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(field.isActive ? Theme.Text.primary : Theme.Text.tertiary)

                        typeBadge
                    }

                    if let unit = field.unit {
                        Text(unit)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.tertiary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { field.isActive },
                    set: { _ in onToggleActive() }
                ))
                .labelsHidden()
                .tint(Theme.Accent.primary)
            }
        }
    }

    private var typeBadge: some View {
        Text(field.fieldType.capitalized)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Accent.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(Theme.Accent.primaryDimmed)
            .clipShape(Capsule())
    }
}
