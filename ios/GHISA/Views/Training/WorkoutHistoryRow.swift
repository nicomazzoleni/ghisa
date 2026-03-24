import SwiftUI

struct WorkoutHistoryRow: View {
    let workout: Workout

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(formattedDate)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Text.primary)

                    Spacer()

                    if let duration = workout.durationMinutes {
                        Text("\(duration) min")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Text.tertiary)
                }

                if !exerciseNames.isEmpty {
                    Text(exerciseNames)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: Theme.Spacing.lg) {
                    Label("\(exerciseCount) exercises", systemImage: "dumbbell")
                    Label("\(setCount) sets", systemImage: "number")
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)

                if let location = workout.location, !location.isEmpty {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(location)
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
                }

                let flags = workout.flagAssignments.map(\.flag)
                if !flags.isEmpty {
                    FlagRow(flags: flags)
                }
            }
        }
    }

    private var formattedDate: String {
        workout.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var exerciseNames: String {
        workout.workoutExercises
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { $0.exercise?.name }
            .joined(separator: ", ")
    }

    private var exerciseCount: Int {
        workout.workoutExercises.count
    }

    private var setCount: Int {
        workout.workoutExercises.reduce(0) { $0 + $1.sets.count }
    }
}
