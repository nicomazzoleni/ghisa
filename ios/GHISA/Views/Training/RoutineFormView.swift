import SwiftData
import SwiftUI

struct RoutineFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: RoutineFormViewModel
    @State private var isEditMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                nameSection
                notesSection
                exercisesSection
                addExerciseButton
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Background.base)
        .navigationTitle(viewModel.isEditing ? "Edit Routine" : "New Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !viewModel.templateExercises.isEmpty {
                    Button(isEditMode ? "Done" : "Reorder") {
                        isEditMode.toggle()
                    }
                    .foregroundStyle(Theme.Text.secondary)
                }

                Button("Save") {
                    do {
                        try viewModel.save()
                        dismiss()
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Accent.primary)
            }
        }
        .sheet(isPresented: $viewModel.showingExercisePicker) {
            ExercisePickerView { exercise in
                viewModel.addExercise(exercise)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.loadExisting()
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        CardView {
            TextField("Routine name", text: $viewModel.name)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Text.primary)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        CardView {
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)
                .lineLimit(1 ... 4)
        }
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        let exercises = viewModel.templateExercises
        let groupLabels = supersetGroupLabels(for: exercises, groupKeyPath: \.supersetGroup)

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if !exercises.isEmpty {
                Text("Exercises")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)

                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, te in
                    HStack(spacing: 0) {
                        if let label = groupLabels[te.id] {
                            SupersetGroupIndicator(label: label)
                        }

                        CardView {
                            RoutineExerciseRow(
                                templateExercise: te,
                                onUpdateTargetSets: { count in
                                    viewModel.updateTargetSets(for: te, count: count)
                                },
                                onRemove: {
                                    viewModel.removeExercise(te)
                                },
                                onMoveUp: isEditMode && index > 0 ? { viewModel.moveExerciseUp(te) } : nil,
                                onMoveDown: isEditMode && index < exercises
                                    .count - 1 ? { viewModel.moveExerciseDown(te) } : nil
                            )
                        }
                    }
                    .contextMenu {
                        routineSupersetMenu(for: te)
                    }
                }
            }
        }
    }

    // MARK: - Superset Menu

    @ViewBuilder
    private func routineSupersetMenu(for te: WorkoutTemplateExercise) -> some View {
        if te.supersetGroup != nil {
            Button {
                viewModel.assignSupersetGroup(te, group: nil)
            } label: {
                Label("Remove from Group", systemImage: "rectangle.on.rectangle.slash")
            }
        }

        let usedGroups = Set(viewModel.templateExercises.compactMap(\.supersetGroup)).sorted()
        if !usedGroups.isEmpty {
            Menu("Join Group") {
                ForEach(usedGroups, id: \.self) { group in
                    Button("Group \(supersetGroupLetter(group))") {
                        viewModel.assignSupersetGroup(te, group: group)
                    }
                }
            }
        }

        Button {
            viewModel.assignSupersetGroup(te, group: viewModel.nextAvailableGroup())
        } label: {
            Label("New Superset Group", systemImage: "rectangle.on.rectangle")
        }
    }

    // MARK: - Add Exercise

    private var addExerciseButton: some View {
        Button {
            viewModel.showingExercisePicker = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
            }
            .font(Theme.Typography.cardTitle)
            .foregroundStyle(Theme.Accent.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(Theme.Accent.primaryDimmed)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
    }
}
