import SwiftUI

struct TrainingPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.Background.base.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Text.tertiary)
                Text("Train")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)
                Text("Coming soon")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.tertiary)
            }
        }
        .navigationTitle("Train")
        .navigationBarTitleDisplayMode(.inline)
    }
}
