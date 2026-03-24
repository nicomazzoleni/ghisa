import SwiftUI

struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Background.base.ignoresSafeArea()
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Text.tertiary)
                    Text("Profile")
                        .font(Theme.Typography.sectionHeader)
                        .foregroundStyle(Theme.Text.primary)
                    Text("Coming soon")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
