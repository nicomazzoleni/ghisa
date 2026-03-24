import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExerciseDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingAddFieldSheet = false
    @State private var isFieldEditMode = false

    private let service: ExerciseService
    private let workoutService: WorkoutService?

    init(service: ExerciseService, exercise: Exercise, workoutService: WorkoutService? = nil) {
        self.service = service
        self.workoutService = workoutService
        _viewModel = State(initialValue: ExerciseDetailViewModel(
            service: service,
            exercise: exercise
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                infoCard
                historyLink
                fieldsSection
                archiveSection
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Background.base)
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                        .foregroundStyle(Theme.Accent.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                ExerciseFormView(
                    service: service,
                    user: viewModel.exercise.user,
                    exercise: viewModel.exercise
                )
            }
        }
        .sheet(isPresented: $showingAddFieldSheet) {
            NavigationStack {
                AddFieldView { name, fieldType, unit, selectOptions in
                    viewModel.addCustomField(
                        name: name,
                        fieldType: fieldType,
                        unit: unit,
                        selectOptions: selectOptions
                    )
                }
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
        .alert(
            "Archive Exercise",
            isPresented: $viewModel.showArchiveConfirmation
        ) {
            Button("Archive", role: .destructive) {
                viewModel.archiveExercise()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Archived exercises won't appear in your library but can be restored later.")
        }
    }

    @ViewBuilder
    private var historyLink: some View {
        if let workoutService {
            NavigationLink {
                ExerciseHistoryView(
                    exercise: viewModel.exercise,
                    user: viewModel.exercise.user,
                    workoutService: workoutService
                )
            } label: {
                CardView {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Theme.Accent.primary)
                        Text("View History")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Text.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var infoCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if !viewModel.exercise.muscleGroups.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Muscle Groups")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.tertiary)
                        Text(viewModel.exercise.muscleGroups.joined(separator: ", "))
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.primary)
                    }
                }

                if viewModel.exercise.muscleGroups.isEmpty {
                    Text("No details added yet")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var fieldsSection: some View {
        let fields = viewModel.sortedFields

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Fields")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)
                Spacer()

                if fields.count > 1 {
                    Button(isFieldEditMode ? "Done" : "Reorder") {
                        isFieldEditMode.toggle()
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)
                }

                Button {
                    showingAddFieldSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.Accent.primary)
                }
            }

            ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                HStack(spacing: Theme.Spacing.sm) {
                    if isFieldEditMode {
                        VStack(spacing: 2) {
                            Button { viewModel.moveFieldUp(field) } label: {
                                Image(systemName: "chevron.up")
                                    .font(.caption2)
                                    .foregroundStyle(index > 0 ? Theme.Text.secondary : Theme.Text.tertiary
                                        .opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(index == 0)

                            Button { viewModel.moveFieldDown(field) } label: {
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(index < fields.count - 1 ? Theme.Text.secondary : Theme.Text
                                        .tertiary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(index == fields.count - 1)
                        }
                    }

                    ExerciseFieldRow(field: field) {
                        viewModel.toggleFieldActive(field)
                    }
                }
            }
        }
    }

    private var archiveSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if viewModel.exercise.isArchived {
                Button {
                    viewModel.restoreExercise()
                } label: {
                    Text("Restore Exercise")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Semantic.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Semantic.success.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
            } else {
                Button {
                    viewModel.showArchiveConfirmation = true
                } label: {
                    Text("Archive Exercise")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Semantic.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Semantic.error.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }
}
