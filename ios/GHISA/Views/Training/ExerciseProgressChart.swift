import Charts
import SwiftUI

struct ExerciseProgressChart: View {
    let dataPoints: [(date: Date, e1rm: Float)]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Estimated 1RM Progress")
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)

                Chart {
                    ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                        if dataPoints.count > 1 {
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("e1RM", point.e1rm)
                            )
                            .foregroundStyle(Theme.Accent.primary)
                            .interpolationMethod(.catmullRom)
                        }

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("e1RM", point.e1rm)
                        )
                        .foregroundStyle(Theme.Accent.primary)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }
}
