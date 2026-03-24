import SwiftUI

struct SupersetGroupIndicator: View {
    let label: String

    private var color: Color {
        let colors: [Color] = [
            Theme.Accent.primary,
            Theme.Semantic.success,
            Theme.Semantic.warning,
            .purple,
            .orange,
            .pink,
        ]
        guard let first = label.unicodeScalars.first else { return colors[0] }
        let index = Int(first.value) - 65 // A=0, B=1, ...
        return colors[index % colors.count]
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(width: 20)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.15))
                .frame(width: 4)
        )
        .padding(.trailing, Theme.Spacing.xs)
    }
}
