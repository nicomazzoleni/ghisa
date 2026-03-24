import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ActiveWorkoutViewModel
    @State private var notesText: String = ""
    @State private var locationText: String = ""
    @State private var isEditMode = false
    @State private var showingDatePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                timerHeader
                workoutFlagsRow
                notesSection
                locationSection
                exercisesList
                addExerciseButton
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Background.base)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Discard") {
                    viewModel.showingDiscardConfirmation = true
                }
                .foregroundStyle(Theme.Semantic.error)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(isEditMode ? "Done" : "Reorder") {
                    isEditMode.toggle()
                }
                .foregroundStyle(Theme.Text.secondary)

                Button("Finish") {
                    viewModel.showingFinishConfirmation = true
                }
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Accent.primary)
            }
        }
        .alert(
            "Discard Workout?",
            isPresented: $viewModel.showingDiscardConfirmation
        ) {
            Button("Discard", role: .destructive) {
                do {
                    try viewModel.discardWorkout()
                    dismiss()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This workout and all logged sets will be permanently deleted.")
        }
        .alert(
            "Finish Workout?",
            isPresented: $viewModel.showingFinishConfirmation
        ) {
            Button("Finish") {
                do {
                    try viewModel.finishWorkout()
                    if !viewModel.showingSaveAsRoutine {
                        dismiss()
                    }
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this workout to your history.")
        }
        .sheet(isPresented: $viewModel.showingSaveAsRoutine) {
            SaveAsRoutineSheet(
                onSave: { name in
                    viewModel.saveAsRoutine(name: name)
                    dismiss()
                },
                onSkip: {
                    viewModel.skipSaveAsRoutine()
                    dismiss()
                }
            )
        }
        .modifier(ActiveWorkoutSheets(
            viewModel: viewModel,
            modelContext: modelContext,
            showingDatePicker: $showingDatePicker
        ))
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            notesText = viewModel.workout.notes ?? ""
            locationText = viewModel.workout.location ?? ""
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(viewModel.formattedElapsedTime)
                .font(Theme.Typography.metricValue)
                .foregroundStyle(Theme.Text.primary)
                .monospacedDigit()

            Button {
                showingDatePicker = true
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(viewModel.workout.date.formatted(date: .abbreviated, time: .shortened))
                    Image(systemName: "pencil")
                        .font(.caption2)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Workout Flags

    private var workoutFlagsRow: some View {
        Button {
            viewModel.showFlagPicker(for: .workout)
        } label: {
            CardView {
                HStack(spacing: Theme.Spacing.sm) {
                    let flags = viewModel.workout.flagAssignments.map(\.flag)
                    if flags.isEmpty {
                        Image(systemName: "flag")
                            .foregroundStyle(Theme.Text.tertiary)
                        Text("Add flags...")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Text.tertiary)
                    } else {
                        FlagRow(flags: flags)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes

    private var notesSection: some View {
        CardView {
            TextField("Workout notes...", text: $notesText, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)
                .lineLimit(1 ... 4)
                .onChange(of: notesText) { _, newValue in
                    viewModel.updateNotes(newValue)
                }
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        CardView {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(Theme.Text.tertiary)
                TextField("Location (optional)", text: $locationText)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.primary)
                    .onChange(of: locationText) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.updateLocation(trimmed.isEmpty ? nil : trimmed)
                    }
            }
        }
    }

    // MARK: - Exercises

    private var exercisesList: some View {
        let exercises = viewModel.sortedExercises
        let groupLabels = supersetGroupLabels(for: exercises, groupKeyPath: \.supersetGroup)

        return ForEach(Array(exercises.enumerated()), id: \.element.id) { index, workoutExercise in
            WorkoutExerciseCard(
                workoutExercise: workoutExercise,
                onAddSet: { viewModel.addSet(to: workoutExercise) },
                onRemoveSet: { set in viewModel.removeSet(set) },
                onUpdateValue: { value, num, text, toggle in
                    viewModel.updateValue(value, number: num, text: text, toggle: toggle)
                },
                onRemoveExercise: { viewModel.removeExercise(workoutExercise) },
                onToggleExerciseFlags: {
                    viewModel.showFlagPicker(for: .exercise(workoutExercise))
                },
                onToggleSetFlags: { set in
                    viewModel.showFlagPicker(for: .set(set))
                },
                onViewHistory: {
                    viewModel.exerciseForHistory = workoutExercise.exercise
                    viewModel.showingExerciseHistory = true
                },
                onUpdateSetNotes: { set, notes in
                    viewModel.updateSetNotes(set, notes: notes)
                },
                onMoveUp: isEditMode && index > 0 ? { viewModel.moveExerciseUp(workoutExercise) } : nil,
                onMoveDown: isEditMode && index < exercises
                    .count - 1 ? { viewModel.moveExerciseDown(workoutExercise) } : nil,
                supersetGroupLabel: groupLabels[workoutExercise.id]
            )
            .contextMenu {
                supersetMenu(for: workoutExercise)
            }
        }
    }

    // MARK: - Superset Menu

    @ViewBuilder
    private func supersetMenu(for exercise: WorkoutExercise) -> some View {
        if exercise.supersetGroup != nil {
            Button {
                viewModel.assignSupersetGroup(exercise, group: nil)
            } label: {
                Label("Remove from Group", systemImage: "rectangle.on.rectangle.slash")
            }
        }

        let usedGroups = Set(viewModel.workout.workoutExercises.compactMap(\.supersetGroup)).sorted()
        if !usedGroups.isEmpty {
            Menu("Join Group") {
                ForEach(usedGroups, id: \.self) { group in
                    Button("Group \(supersetGroupLetter(group))") {
                        viewModel.assignSupersetGroup(exercise, group: group)
                    }
                }
            }
        }

        Button {
            viewModel.assignSupersetGroup(exercise, group: viewModel.nextAvailableGroup())
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

// MARK: - Sheets Modifier

private struct ActiveWorkoutSheets: ViewModifier {
    @Bindable var viewModel: ActiveWorkoutViewModel
    var modelContext: ModelContext
    @Binding var showingDatePicker: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.showingExercisePicker) {
                ExercisePickerView { exercise in
                    viewModel.addExercise(exercise)
                }
            }
            .sheet(isPresented: $viewModel.showingFlagPicker) {
                flagPickerSheet
            }
            .sheet(isPresented: $viewModel.showingExerciseHistory) {
                exerciseHistorySheet
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
            }
    }

    private var flagPickerSheet: some View {
        FlagPicker(
            scope: viewModel.flagPickerScope,
            currentAssignments: viewModel.flagPickerAssignments,
            user: viewModel.workout.user,
            flagService: FlagService(modelContext: modelContext),
            onAssign: { flag in viewModel.assignFlag(flag) },
            onRemove: { assignment in viewModel.removeAssignment(assignment) }
        )
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var exerciseHistorySheet: some View {
        if let exercise = viewModel.exerciseForHistory {
            NavigationStack {
                ExerciseHistoryView(
                    exercise: exercise,
                    user: viewModel.workout.user,
                    workoutService: WorkoutService(modelContext: modelContext)
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            viewModel.showingExerciseHistory = false
                        }
                        .foregroundStyle(Theme.Accent.primary)
                    }
                }
            }
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Workout Date",
                selection: Binding(
                    get: { viewModel.workout.date },
                    set: { viewModel.updateWorkoutDate($0) }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .padding(Theme.Spacing.lg)
            .navigationTitle("Edit Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingDatePicker = false
                    }
                    .foregroundStyle(Theme.Accent.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
