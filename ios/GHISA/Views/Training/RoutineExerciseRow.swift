import SwiftUI

struct RoutineExerciseRow: View {
    let templateExercise: WorkoutTemplateExercise
    let onUpdateTargetSets: (Int) -> Void
    let onRemove: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    @State private var showFieldTargets = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                if onMoveUp != nil || onMoveDown != nil {
                    VStack(spacing: 2) {
                        Button { onMoveUp?() } label: {
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundStyle(onMoveUp != nil ? Theme.Text.secondary : Theme.Text.tertiary
                                    .opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(onMoveUp == nil)

                        Button { onMoveDown?() } label: {
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(onMoveDown != nil ? Theme.Text.secondary : Theme.Text.tertiary
                                    .opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(onMoveDown == nil)
                    }
                    .padding(.trailing, Theme.Spacing.xs)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Text.primary)

                    if let groups = templateExercise.exercise?.muscleGroups, !groups.isEmpty {
                        Text(groups.joined(separator: " · "))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.tertiary)
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Theme.Semantic.error)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: Theme.Spacing.md) {
                Text("Target Sets")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.secondary)

                Spacer()

                Stepper(
                    value: Binding(
                        get: { templateExercise.targetSets ?? 3 },
                        set: { onUpdateTargetSets($0) }
                    ),
                    in: 1 ... 20
                ) {
                    Text("\(templateExercise.targetSets ?? 3)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.primary)
                        .monospacedDigit()
                }
            }

            // Field Targets
            let activeFields = (templateExercise.exercise?.fieldDefinitions ?? [])
                .filter(\.isActive)
                .sorted { $0.sortOrder < $1.sortOrder }
            if !activeFields.isEmpty {
                DisclosureGroup("Field Targets", isExpanded: $showFieldTargets) {
                    ForEach(activeFields) { field in
                        fieldTargetRow(field)
                    }
                }
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.secondary)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func fieldTargetRow(_ field: ExerciseFieldDefinition) -> some View {
        let existingTarget = templateExercise.fieldTargets.first { $0.fieldDefinition.id == field.id }

        return HStack {
            Text(field.name)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)

            Spacer()

            if field.fieldType == "number" {
                TextField(
                    field.unit ?? "value",
                    text: Binding(
                        get: {
                            if let num = existingTarget?.targetValueNumber {
                                return num.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(num))" : "\(num)"
                            }
                            return ""
                        },
                        set: { _ in
                            // This is read-only display for now; targets are set via RoutineFormViewModel
                        }
                    )
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)
            } else {
                Text(existingTarget?.targetValueText ?? "—")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.primary)
            }
        }
    }
}
