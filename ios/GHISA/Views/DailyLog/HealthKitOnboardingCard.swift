import SwiftUI

struct HealthKitOnboardingCard: View {
    let isImporting: Bool
    let onConnect: () -> Void

    var body: some View {
        CardView {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("Connect Apple Health")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Text.primary)

                    Text("Auto-import sleep, steps, heart rate, and more to see how your lifestyle affects training.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    onConnect()
                } label: {
                    Group {
                        if isImporting {
                            HStack(spacing: Theme.Spacing.sm) {
                                ProgressView()
                                    .tint(.white)
                                Text("Importing data…")
                            }
                        } else {
                            Text("Connect Health")
                        }
                    }
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(Theme.Accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .buttonStyle(.plain)
                .disabled(isImporting)
            }
        }
    }
}
