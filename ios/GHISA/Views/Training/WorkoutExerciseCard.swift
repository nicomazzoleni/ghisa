import SwiftUI

struct WorkoutExerciseCard: View {
    let workoutExercise: WorkoutExercise
    let onAddSet: () -> Void
    let onRemoveSet: (WorkoutSet) -> Void
    let onUpdateValue: (WorkoutSetValue, Float?, String?, Bool?) -> Void
    let onRemoveExercise: () -> Void
    var onToggleExerciseFlags: (() -> Void)?
    var onToggleSetFlags: ((WorkoutSet) -> Void)?
    var onViewHistory: (() -> Void)?
    var onUpdateSetNotes: ((WorkoutSet, String?) -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onMoveSetUp: ((WorkoutSet) -> Void)?
    var onMoveSetDown: ((WorkoutSet) -> Void)?
    var supersetGroupLabel: String?

    var body: some View {
        HStack(spacing: 0) {
            if let label = supersetGroupLabel {
                SupersetGroupIndicator(label: label)
            }

            CardView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header
                    exerciseFlags
                    columnHeaders
                    setRows
                    addSetButton
                }
            }
        }
    }

    private var exerciseName: String {
        workoutExercise.exercise?.name ?? "Unknown Exercise"
    }

    private var activeFields: [ExerciseFieldDefinition] {
        (workoutExercise.exercise?.fieldDefinitions ?? [])
            .filter(\.isActive)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var sortedSets: [WorkoutSet] {
        workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if onMoveUp != nil || onMoveDown != nil {
                VStack(spacing: 2) {
                    Button { onMoveUp?() } label: {
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                            .foregroundStyle(onMoveUp != nil ? Theme.Text.secondary : Theme.Text.tertiary.opacity(0.3))
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
                Text(exerciseName)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)

                if let groups = workoutExercise.exercise?.muscleGroups, !groups.isEmpty {
                    Text(groups.joined(separator: " \u{00B7} "))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }

            Spacer()

            Menu {
                if let onViewHistory {
                    Button {
                        onViewHistory()
                    } label: {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                    }
                }
                if let onToggleExerciseFlags {
                    Button {
                        onToggleExerciseFlags()
                    } label: {
                        Label("Flags", systemImage: "flag")
                    }
                }
                Button("Remove Exercise", role: .destructive) {
                    onRemoveExercise()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(Theme.Text.secondary)
                    .padding(Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Exercise Flags

    @ViewBuilder
    private var exerciseFlags: some View {
        let flags = workoutExercise.flagAssignments.map(\.flag)
        if !flags.isEmpty {
            FlagRow(flags: flags)
        }
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Set")
                .frame(width: 28)

            ForEach(activeFields) { field in
                Text(field.unit.map { "\(field.name) (\($0))" } ?? field.name)
                    .frame(minWidth: 56)
            }

            Spacer(minLength: 0)
            // Spacer for delete button column
            Color.clear.frame(width: 24, height: 1)
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.Text.tertiary)
    }

    // MARK: - Set Rows

    private var setRows: some View {
        ForEach(Array(sortedSets.enumerated()), id: \.element.id) { _, set in
            SetEntryRow(
                set: set,
                activeFields: activeFields,
                onUpdateValue: onUpdateValue,
                onDelete: { onRemoveSet(set) },
                onToggleSetFlags: onToggleSetFlags.map { callback in
                    { callback(set) }
                },
                onUpdateNotes: onUpdateSetNotes.map { callback in
                    { notes in callback(set, notes) }
                }
            )

            if set.id != sortedSets.last?.id {
                Divider()
                    .overlay(Theme.Background.divider)
            }
        }
    }

    // MARK: - Add Set

    private var addSetButton: some View {
        Button {
            onAddSet()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("Add Set")
            }
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Accent.primary)
        }
        .buttonStyle(.plain)
    }
}
