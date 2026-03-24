import SwiftUI

struct SaveAsRoutineSheet: View {
    @State var routineName: String = ""
    let onSave: (String) -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Accent.primary)

                Text("Save as routine?")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)

                Text("Reuse this workout structure to quick-start future sessions")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)

                CardView {
                    TextField("Routine name", text: $routineName)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Text.primary)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.md) {
                    Button {
                        let name = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        onSave(name)
                    } label: {
                        Text("Save Routine")
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.lg)
                            .background(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Theme.Text.tertiary
                                : Theme.Accent.primary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                    .buttonStyle(.plain)
                    .disabled(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        onSkip()
                    } label: {
                        Text("Skip")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
            .background(Theme.Background.base)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
