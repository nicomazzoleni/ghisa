import SwiftUI

struct RoutineCardView: View {
    let template: WorkoutTemplate

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(template.name)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)
                    .lineLimit(1)

                let exerciseCount = template.exercises.count
                let totalSets = template.exercises.compactMap(\.targetSets).reduce(0, +)
                Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") · \(totalSets) sets")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
            }
            .frame(width: 140, alignment: .leading)
        }
    }
}
