import SwiftUI

struct HealthKitMetricCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()

                Text(value)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)
                    +
                    Text(" \(unit)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)

                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 80)
        }
    }
}
