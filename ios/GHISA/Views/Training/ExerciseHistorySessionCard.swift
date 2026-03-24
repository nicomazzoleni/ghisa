import SwiftUI

struct ExerciseHistorySessionCard: View {
    let session: HistorySession
    let activeFields: [ExerciseFieldDefinition]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(session.workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)

                // Column headers
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Set")
                        .frame(width: 28, alignment: .leading)

                    ForEach(activeFields) { field in
                        Text(field.unit.map { "\(field.name) (\($0))" } ?? field.name)
                            .frame(minWidth: 56, alignment: .leading)
                    }

                    Spacer(minLength: 0)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)

                // Set rows
                ForEach(session.sets, id: \.workoutSet.id) { historySet in
                    VStack(spacing: 0) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Text("\(historySet.setNumber)")
                                .font(Theme.Typography.callout)
                                .foregroundStyle(Theme.Text.tertiary)
                                .frame(width: 28, alignment: .leading)

                            ForEach(activeFields) { field in
                                Text(displayValue(for: field, in: historySet.workoutSet))
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Text.primary)
                                    .frame(minWidth: 56, alignment: .leading)
                            }

                            Spacer(minLength: 0)

                            // PR badges
                            ForEach(Array(historySet.prBadges), id: \.self) { pr in
                                Text(prLabel(pr))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(prColor(pr))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)

                        if let notes = historySet.workoutSet.notes, !notes.isEmpty {
                            Text(notes)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Text.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 28 + Theme.Spacing.sm)
                                .padding(.bottom, Theme.Spacing.xs)
                        }
                    }
                }
            }
        }
    }

    private func prLabel(_ pr: PRType) -> String {
        switch pr {
            case .heaviestWeight: "PR Weight"
            case .mostRepsAtWeight: "PR Reps"
            case .bestE1RM: "PR e1RM"
        }
    }

    private func prColor(_ pr: PRType) -> Color {
        switch pr {
            case .heaviestWeight: Theme.Accent.primary
            case .mostRepsAtWeight: Theme.Semantic.success
            case .bestE1RM: Theme.Semantic.warning
        }
    }
}
