import SwiftData
import SwiftUI

private struct WorkoutHistoryDestination: Hashable {
    let user: User
}

struct TrainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TrainTabViewModel?
    @State private var activeWorkout: Workout?
    @State private var isShowingActiveWorkout = false
    @State private var errorMessage: String?
    @State private var templateToStart: WorkoutTemplate?

    var body: some View {
        Group {
            if let vm = viewModel {
                trainContent(vm)
            } else {
                ProgressView()
                    .onAppear { setupViewModel() }
            }
        }
        .navigationTitle("Train")
        .navigationDestination(isPresented: $isShowingActiveWorkout) {
            if let workout = activeWorkout {
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutViewModel(
                        workout: workout,
                        workoutService: WorkoutService(modelContext: modelContext),
                        flagService: FlagService(modelContext: modelContext),
                        templateService: WorkoutTemplateService(modelContext: modelContext)
                    )
                )
            }
        }
        .navigationDestination(for: Workout.self) { workout in
            WorkoutDetailView(workout: workout)
        }
        .navigationDestination(for: WorkoutHistoryDestination.self) { destination in
            WorkoutHistoryListView(user: destination.user)
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(
            "Start Routine?",
            isPresented: Binding(
                get: { templateToStart != nil },
                set: { if !$0 { templateToStart = nil } }
            )
        ) {
            Button("Start") {
                if let vm = viewModel, let template = templateToStart {
                    startFromTemplate(vm, template: template)
                }
                templateToStart = nil
            }
            Button("Cancel", role: .cancel) {
                templateToStart = nil
            }
        } message: {
            if let template = templateToStart {
                let count = template.exercises.count
                Text("Start \"\(template.name)\" with \(count) exercise\(count == 1 ? "" : "s") pre-loaded.")
            }
        }
        .onChange(of: isShowingActiveWorkout) { _, showing in
            if !showing {
                activeWorkout = nil
                viewModel?.loadState()
            }
        }
    }

    private func trainContent(_ vm: TrainTabViewModel) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if let inProgress = vm.inProgressWorkout {
                    resumeBanner(inProgress)
                } else {
                    startButton(vm)
                }

                routinesSection(vm)

                exerciseLibraryLink
                flagLibraryLink

                if !vm.completedWorkouts.isEmpty {
                    recentWorkoutsSection(vm)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .contentMargins(.bottom, 32, for: .scrollContent)
        .background(Theme.Background.base)
        .onAppear { vm.loadState() }
    }

    // MARK: - Routines Section

    private func routinesSection(_ vm: TrainTabViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("My Routines")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)

                Spacer()

                if !vm.templates.isEmpty {
                    NavigationLink {
                        routineListDestination
                    } label: {
                        Text("See All")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Accent.primary)
                    }
                }
            }

            if vm.templates.isEmpty {
                NavigationLink {
                    routineFormDestination(template: nil)
                } label: {
                    CardView {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Theme.Accent.primary)
                            Text("Create your first routine")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Text.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.Text.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(vm.templates) { template in
                            Button {
                                templateToStart = template
                            } label: {
                                RoutineCardView(template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func startFromTemplate(_ vm: TrainTabViewModel, template: WorkoutTemplate) {
        do {
            let workout = try vm.startFromTemplate(template)
            activeWorkout = workout
            isShowingActiveWorkout = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Resume Banner

    private func resumeBanner(_ workout: Workout) -> some View {
        Button {
            activeWorkout = workout
            isShowingActiveWorkout = true
        } label: {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(Theme.Semantic.success)
                                .frame(width: 8, height: 8)
                            Text("Workout in progress")
                                .font(Theme.Typography.cardTitle)
                                .foregroundStyle(Theme.Text.primary)
                        }

                        let exerciseCount = workout.workoutExercises.count
                        let elapsed = elapsedString(from: workout.startedAt)
                        Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") \u{00B7} \(elapsed)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start Button

    private func startButton(_ vm: TrainTabViewModel) -> some View {
        Button {
            do {
                let workout = try vm.startNewWorkout()
                activeWorkout = workout
                isShowingActiveWorkout = true
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("Start Workout")
            }
            .font(Theme.Typography.cardTitle)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(Theme.Accent.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise Library Link

    private var exerciseLibraryLink: some View {
        NavigationLink {
            ExerciseLibraryView()
        } label: {
            CardView {
                HStack {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundStyle(Theme.Accent.primary)
                        Text("Exercise Library")
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(Theme.Text.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flag Library Link

    private var flagLibraryLink: some View {
        NavigationLink {
            FlagLibraryView()
        } label: {
            CardView {
                HStack {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "flag")
                            .font(.title3)
                            .foregroundStyle(Theme.Accent.primary)
                        Text("Manage Flags")
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(Theme.Text.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Workouts

    private func recentWorkoutsSection(_ vm: TrainTabViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Recent Workouts")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)

                Spacer()

                if let user = viewModel.flatMap({ _ in fetchUser() }) {
                    NavigationLink(value: WorkoutHistoryDestination(user: user)) {
                        Text("See All")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Accent.primary)
                    }
                }
            }

            ForEach(vm.completedWorkouts) { workout in
                NavigationLink(value: workout) {
                    WorkoutHistoryRow(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Helpers

extension TrainTabView {
    private func elapsedString(from start: Date?) -> String {
        guard let start else { return "" }
        let seconds = Int(Date.now.timeIntervalSince(start))
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }

    private func setupViewModel() {
        guard let user = fetchUser() else { return }
        let workoutService = WorkoutService(modelContext: modelContext)
        let templateService = WorkoutTemplateService(modelContext: modelContext)
        let vm = TrainTabViewModel(workoutService: workoutService, templateService: templateService, user: user)
        vm.loadState()
        viewModel = vm
    }

    private func fetchUser() -> User? {
        try? modelContext.fetch(FetchDescriptor<User>()).first
    }

    @ViewBuilder
    private var routineListDestination: some View {
        let service = WorkoutTemplateService(modelContext: modelContext)
        if let user = fetchUser() {
            RoutineListView(
                viewModel: RoutineListViewModel(templateService: service, user: user)
            )
        }
    }

    @ViewBuilder
    private func routineFormDestination(template: WorkoutTemplate?) -> some View {
        let service = WorkoutTemplateService(modelContext: modelContext)
        if let user = fetchUser() {
            RoutineFormView(
                viewModel: RoutineFormViewModel(templateService: service, user: user, template: template)
            )
        }
    }
}
