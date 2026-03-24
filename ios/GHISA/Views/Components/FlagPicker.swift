import SwiftUI

struct FlagPicker: View {
    let scope: String
    let currentAssignments: [FlagAssignment]
    let user: User
    let flagService: FlagService
    let onAssign: (Flag) -> Void
    let onRemove: (FlagAssignment) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateFlag = false
    @State private var errorMessage: String?

    private var availableFlags: [Flag] {
        flagService.fetchFlags(for: user, scope: scope)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if availableFlags.isEmpty {
                        Text("No \(scope) flags yet")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.tertiary)
                    } else {
                        ForEach(availableFlags, id: \.id) { flag in
                            flagToggleRow(flag)
                        }
                    }
                }

                Section {
                    Button {
                        showingCreateFlag = true
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Flag")
                        }
                        .foregroundStyle(Theme.Accent.primary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Background.base)
            .navigationTitle("\(scope.capitalized) Flags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreateFlag) {
                FlagFormView(
                    user: user,
                    flagService: flagService,
                    fixedScope: scope
                )
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func flagToggleRow(_ flag: Flag) -> some View {
        let assignment = currentAssignments.first { $0.flag.id == flag.id }
        let isAssigned = assignment != nil

        return Button {
            if let assignment {
                onRemove(assignment)
            } else {
                onAssign(flag)
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                FlagBadge(flag: flag)
                Spacer()
                if isAssigned {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.Accent.primary)
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(Theme.Text.primary)
    }
}
