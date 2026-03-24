import SwiftData
import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ExerciseLibraryViewModel?
    @State private var showingCreateSheet = false

    var body: some View {
        Group {
            if let vm = viewModel {
                exerciseList(vm)
            } else {
                ProgressView()
                    .onAppear { setupViewModel() }
            }
        }
        .navigationTitle("Exercises")
        .sheet(isPresented: $showingCreateSheet) {
            if viewModel != nil, let user = fetchUser() {
                NavigationStack {
                    ExerciseFormView(
                        service: makeService(),
                        user: user
                    )
                }
            }
        }
        .onChange(of: showingCreateSheet) { _, showing in
            if !showing { viewModel?.loadExercises() }
        }
    }

    private func exerciseList(_ vm: ExerciseLibraryViewModel) -> some View {
        VStack(spacing: 0) {
            if vm.exercises.isEmpty {
                emptyState
            } else {
                exerciseGroupedList(vm)
            }
        }
        .background(Theme.Background.base)
        .searchable(text: Binding(
            get: { vm.searchText },
            set: { vm.searchText = $0 }
        ))
        .toolbar { libraryToolbar(vm) }
    }

    private func exerciseGroupedList(_ vm: ExerciseLibraryViewModel) -> some View {
        List {
            ForEach(vm.groupedExercises, id: \.0) { group, exercises in
                Section {
                    ForEach(exercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(
                                service: makeService(),
                                exercise: exercise,
                                workoutService: WorkoutService(modelContext: modelContext)
                            )
                        } label: {
                            exerciseRow(exercise)
                        }
                        .listRowBackground(Theme.Background.surface)
                    }
                } header: {
                    Text(group)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Text.secondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ToolbarContentBuilder
    private func libraryToolbar(_ vm: ExerciseLibraryViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: Theme.Spacing.md) {
                Menu {
                    Toggle("Show Archived", isOn: Binding(
                        get: { vm.showArchived },
                        set: {
                            vm.showArchived = $0
                            vm.loadExercises()
                        }
                    ))
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Theme.Text.secondary)
                }

                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.Accent.primary)
                }
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(exercise.name)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Text.primary)

                if exercise.isArchived {
                    Text("Archived")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Semantic.warning)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Theme.Semantic.warning.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            if !exercise.muscleGroups.isEmpty {
                Text(exercise.muscleGroups.joined(separator: " \u{00B7} "))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Text.tertiary)
            Text("No exercises yet")
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(Theme.Text.primary)
            Text("Tap + to create your first exercise")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func setupViewModel() {
        guard let user = fetchUser() else { return }
        let service = makeService()
        let vm = ExerciseLibraryViewModel(service: service, user: user)
        vm.loadExercises()
        viewModel = vm
    }

    private func makeService() -> ExerciseService {
        ExerciseService(modelContext: modelContext)
    }

    private func fetchUser() -> User? {
        try? modelContext.fetch(FetchDescriptor<User>()).first
    }
}
