import SwiftUI

struct DailyLogPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.Background.base.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Text.tertiary)
                Text("Daily Log")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)
                Text("Coming soon")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.tertiary)
            }
        }
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}
