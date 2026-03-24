import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Theme.Spacing.lg)
            .background(Theme.Background.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
