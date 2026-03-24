import SwiftData
import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExerciseLibraryViewModel?
    @State private var showingCreateSheet = false

    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    pickerList(vm)
                } else {
                    ProgressView()
                        .onAppear { setupViewModel() }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Accent.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                if let user = fetchUser() {
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
    }

    private func pickerList(_ vm: ExerciseLibraryViewModel) -> some View {
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
    }

    private func exerciseGroupedList(_ vm: ExerciseLibraryViewModel) -> some View {
        List {
            ForEach(vm.groupedExercises, id: \.0) { group, exercises in
                Section {
                    ForEach(exercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
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

    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(exercise.name)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Text.primary)

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
            Text("Create your first exercise to get started")
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
