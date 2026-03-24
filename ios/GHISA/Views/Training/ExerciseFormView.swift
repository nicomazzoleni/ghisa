import SwiftData
import SwiftUI

struct ExerciseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExerciseFormViewModel

    init(service: ExerciseService, user: User, exercise: Exercise? = nil) {
        _viewModel = State(initialValue: ExerciseFormViewModel(
            service: service,
            user: user,
            exercise: exercise
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Name
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Name")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Text.secondary)

                    TextField("e.g. Bench Press", text: $viewModel.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.primary)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                }

                // Muscle Groups
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ComboBoxField(
                        label: "Muscle Group",
                        text: $viewModel.muscleGroupText,
                        suggestions: viewModel.muscleGroupSuggestions,
                        placeholder: "e.g. Chest"
                    )

                    HStack {
                        Spacer()
                        Button {
                            viewModel.addMuscleGroup()
                        } label: {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(Theme.Typography.callout)
                                .foregroundStyle(Theme.Accent.primary)
                        }
                        .disabled(viewModel.muscleGroupText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !viewModel.muscleGroups.isEmpty {
                        FlowLayout(spacing: Theme.Spacing.sm) {
                            ForEach(Array(viewModel.muscleGroups.enumerated()), id: \.offset) { index, group in
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text(group)
                                        .font(Theme.Typography.callout)
                                        .foregroundStyle(Theme.Text.primary)
                                    Button {
                                        viewModel.removeMuscleGroup(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(Theme.Text.tertiary)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Accent.primaryDimmed)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Background.base)
        .navigationTitle(viewModel.isEditMode ? "Edit Exercise" : "New Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Theme.Text.secondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveExercise() }
                    .foregroundStyle(viewModel.isValid ? Theme.Accent.primary : Theme.Text.tertiary)
                    .disabled(!viewModel.isValid)
            }
        }
        .onAppear {
            viewModel.loadSuggestions()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func saveExercise() {
        do {
            _ = try viewModel.save()
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Flow Layout for muscle group chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
