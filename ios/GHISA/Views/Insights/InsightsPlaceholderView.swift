import SwiftUI

struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.Background.base.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Text.tertiary)
                Text("Insights")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)
                Text("Coming soon")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.tertiary)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
