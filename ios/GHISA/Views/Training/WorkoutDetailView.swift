import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let workout: Workout

    @State private var copiedWorkout: Workout?
    @State private var isShowingCopiedWorkout = false
    @State private var showingSaveAsRoutine = false
    @State private var showingDatePicker = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                summaryHeader
                workoutLocation
                workoutFlags
                workoutNotes
                exerciseCards
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Background.base)
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        copyWorkout()
                    } label: {
                        Label("Copy Workout", systemImage: "doc.on.doc")
                    }
                    Button {
                        showingSaveAsRoutine = true
                    } label: {
                        Label("Save as Routine", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        showingDatePicker = true
                    } label: {
                        Label("Edit Date", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.Accent.primary)
                }
            }
        }
        .navigationDestination(isPresented: $isShowingCopiedWorkout) {
            if let copiedWorkout {
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutViewModel(
                        workout: copiedWorkout,
                        workoutService: WorkoutService(modelContext: modelContext),
                        flagService: FlagService(modelContext: modelContext),
                        templateService: WorkoutTemplateService(modelContext: modelContext)
                    )
                )
            }
        }
        .sheet(isPresented: $showingSaveAsRoutine) {
            SaveAsRoutineSheet(
                onSave: { name in
                    saveAsRoutine(name: name)
                    showingSaveAsRoutine = false
                },
                onSkip: {
                    showingSaveAsRoutine = false
                }
            )
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Workout Date",
                    selection: Binding(
                        get: { workout.date },
                        set: { newDate in
                            let service = WorkoutService(modelContext: modelContext)
                            try? service.updateWorkoutDate(workout, date: newDate)
                        }
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
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func copyWorkout() {
        do {
            let user = workout.user
            let service = WorkoutService(modelContext: modelContext)
            let newWorkout = try service.copyWorkout(user: user, source: workout)
            copiedWorkout = newWorkout
            isShowingCopiedWorkout = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveAsRoutine(name: String) {
        do {
            let service = WorkoutTemplateService(modelContext: modelContext)
            _ = try service.createTemplate(from: workout, user: workout.user, name: name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        CardView {
            HStack(spacing: Theme.Spacing.xl) {
                statItem(
                    value: "\(sortedExercises.count)",
                    label: "Exercises"
                )
                statItem(
                    value: "\(totalSets)",
                    label: "Sets"
                )
                if let duration = workout.durationMinutes {
                    statItem(
                        value: "\(duration)",
                        label: "Minutes"
                    )
                }
                Spacer()
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(Theme.Text.primary)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)
        }
    }

    // MARK: - Location

    @ViewBuilder
    private var workoutLocation: some View {
        if let location = workout.location, !location.isEmpty {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(Theme.Text.tertiary)
                Text(location)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)
            }
        }
    }

    // MARK: - Workout-Level Flags

    private var workoutFlags: some View {
        FlagRow(flags: workout.flagAssignments.map(\.flag))
    }

    // MARK: - Workout Notes

    @ViewBuilder
    private var workoutNotes: some View {
        if let notes = workout.notes, !notes.isEmpty {
            CardView {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Notes")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Text.tertiary)
                    Text(notes)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Exercise Cards

    private var exerciseCards: some View {
        let groupLabels = supersetGroupLabels(for: sortedExercises, groupKeyPath: \.supersetGroup)

        return ForEach(sortedExercises) { workoutExercise in
            HStack(spacing: 0) {
                if let label = groupLabels[workoutExercise.id] {
                    SupersetGroupIndicator(label: label)
                }

                CardView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        exerciseHeader(workoutExercise)
                        exerciseFlags(workoutExercise)
                        setTable(workoutExercise)
                        exerciseNotes(workoutExercise)
                    }
                }
            }
        }
    }

    private func exerciseHeader(_ workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Text.primary)

            if let groups = workoutExercise.exercise?.muscleGroups, !groups.isEmpty {
                Text(groups.joined(separator: " \u{00B7} "))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
            }
        }
    }

    private func exerciseFlags(_ workoutExercise: WorkoutExercise) -> some View {
        FlagRow(flags: workoutExercise.flagAssignments.map(\.flag))
    }

    // MARK: - Set Table

    private func setTable(_ workoutExercise: WorkoutExercise) -> some View {
        let fields = activeFields(for: workoutExercise)
        let sets = workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }

        return VStack(spacing: 0) {
            // Column headers
            HStack(spacing: Theme.Spacing.sm) {
                Text("Set")
                    .frame(width: 28, alignment: .leading)

                ForEach(fields) { field in
                    Text(field.unit.map { "\(field.name) (\($0))" } ?? field.name)
                        .frame(minWidth: 56, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Text.tertiary)
            .padding(.bottom, Theme.Spacing.sm)

            // Set rows
            ForEach(sets) { set in
                setRow(set, fields: fields)

                if set.id != sets.last?.id {
                    Divider()
                        .overlay(Theme.Background.divider)
                }
            }
        }
    }

    private func setRow(_ set: WorkoutSet, fields: [ExerciseFieldDefinition]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.sm) {
                Text("\(set.setNumber)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Text.tertiary)
                    .frame(width: 28, alignment: .leading)

                ForEach(fields) { field in
                    Text(displayValue(for: field, in: set))
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.primary)
                        .frame(minWidth: 56, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, Theme.Spacing.xs)

            // Set-level flags
            let setFlags = set.flagAssignments.map(\.flag)
            if !setFlags.isEmpty {
                FlagRow(flags: setFlags)
                    .padding(.bottom, Theme.Spacing.xs)
            }

            // Set notes
            if let notes = set.notes, !notes.isEmpty {
                Text(notes)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 28 + Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.xs)
            }
        }
    }

    @ViewBuilder
    private func exerciseNotes(_ workoutExercise: WorkoutExercise) -> some View {
        if let notes = workoutExercise.notes, !notes.isEmpty {
            Text(notes)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.secondary)
                .italic()
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        workout.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var sortedExercises: [WorkoutExercise] {
        workout.workoutExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var totalSets: Int {
        workout.workoutExercises.reduce(0) { $0 + $1.sets.count }
    }

    private func activeFields(for workoutExercise: WorkoutExercise) -> [ExerciseFieldDefinition] {
        (workoutExercise.exercise?.fieldDefinitions ?? [])
            .filter(\.isActive)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // displayValue is now a shared free function in Utils/FieldFormatting.swift
}
