import SwiftUI

struct FlagBadge: View {
    let flag: Flag

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let icon = flag.icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(flag.name)
                .font(Theme.Typography.caption)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Color(hex: flag.color).opacity(0.2))
        .foregroundStyle(Color(hex: flag.color))
        .clipShape(Capsule())
    }
}

struct FlagRow: View {
    let flags: [Flag]

    var body: some View {
        if !flags.isEmpty {
            FlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(flags, id: \.id) { flag in
                    FlagBadge(flag: flag)
                }
            }
        }
    }
}
