import SwiftData
import SwiftUI

struct WorkoutHistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workouts: [Workout] = []
    @State private var searchText = ""
    @State private var showingFilter = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    @State private var filterFlags: Set<UUID> = []
    @State private var filterMuscleGroup: String?
    @State private var availableFlags: [Flag] = []
    @State private var availableMuscleGroups: [String] = []

    let user: User

    var body: some View {
        Group {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "dumbbell",
                    description: Text("Completed workouts will appear here.")
                )
            } else if filteredWorkouts.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(filteredWorkouts) { workout in
                            NavigationLink(value: workout) {
                                WorkoutHistoryRow(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
        .background(Theme.Background.base)
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search exercises...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilter = true
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" :
                        "line.3.horizontal.decrease.circle")
                        .foregroundStyle(hasActiveFilters ? Theme.Accent.primary : Theme.Text.secondary)
                }
            }
        }
        .sheet(isPresented: $showingFilter) {
            NavigationStack {
                WorkoutHistoryFilterSheet(
                    startDate: $filterStartDate,
                    endDate: $filterEndDate,
                    selectedFlags: $filterFlags,
                    selectedMuscleGroup: $filterMuscleGroup,
                    availableFlags: availableFlags,
                    availableMuscleGroups: availableMuscleGroups,
                    onClear: clearFilters
                )
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear { loadWorkouts() }
    }

    private var hasActiveFilters: Bool {
        filterStartDate != nil || filterEndDate != nil || !filterFlags.isEmpty || filterMuscleGroup != nil
    }

    private var filteredWorkouts: [Workout] {
        var result = workouts

        // Search by exercise name
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { workout in
                workout.workoutExercises.contains { we in
                    we.exercise?.name.lowercased().contains(query) == true
                }
            }
        }

        // Date range
        if let start = filterStartDate {
            result = result.filter { $0.date >= start }
        }
        if let end = filterEndDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
            result = result.filter { $0.date < endOfDay }
        }

        // Flags
        if !filterFlags.isEmpty {
            result = result.filter { workout in
                workout.flagAssignments.contains { filterFlags.contains($0.flag.id) }
            }
        }

        // Muscle group
        if let group = filterMuscleGroup {
            result = result.filter { workout in
                workout.workoutExercises.contains { we in
                    we.exercise?.muscleGroups.contains(group) == true
                }
            }
        }

        return result
    }

    private func clearFilters() {
        filterStartDate = nil
        filterEndDate = nil
        filterFlags = []
        filterMuscleGroup = nil
    }

    private func loadWorkouts() {
        let service = WorkoutService(modelContext: modelContext)
        do {
            workouts = try service.fetchCompletedWorkouts(for: user, limit: 200)
        } catch {
            workouts = []
        }

        // Load available flags and muscle groups for filter
        let flagService = FlagService(modelContext: modelContext)
        availableFlags = flagService.fetchFlags(for: user, scope: "workout")

        let exerciseService = ExerciseService(modelContext: modelContext)
        availableMuscleGroups = (try? exerciseService.fetchDistinctMuscleGroups(for: user)) ?? []
    }
}

// MARK: - Filter Sheet

struct WorkoutHistoryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var selectedFlags: Set<UUID>
    @Binding var selectedMuscleGroup: String?
    let availableFlags: [Flag]
    let availableMuscleGroups: [String]
    let onClear: () -> Void

    @State private var useStartDate = false
    @State private var useEndDate = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()

    var body: some View {
        Form {
            Section("Date Range") {
                Toggle("From", isOn: $useStartDate)
                if useStartDate {
                    DatePicker("Start", selection: $tempStartDate, displayedComponents: .date)
                }

                Toggle("To", isOn: $useEndDate)
                if useEndDate {
                    DatePicker("End", selection: $tempEndDate, displayedComponents: .date)
                }
            }

            if !availableFlags.isEmpty {
                Section("Flags") {
                    ForEach(availableFlags) { flag in
                        Button {
                            if selectedFlags.contains(flag.id) {
                                selectedFlags.remove(flag.id)
                            } else {
                                selectedFlags.insert(flag.id)
                            }
                        } label: {
                            HStack {
                                FlagBadge(flag: flag)
                                Spacer()
                                if selectedFlags.contains(flag.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Accent.primary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !availableMuscleGroups.isEmpty {
                Section("Muscle Group") {
                    ForEach(availableMuscleGroups, id: \.self) { group in
                        Button {
                            selectedMuscleGroup = selectedMuscleGroup == group ? nil : group
                        } label: {
                            HStack {
                                Text(group)
                                    .foregroundStyle(Theme.Text.primary)
                                Spacer()
                                if selectedMuscleGroup == group {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Accent.primary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                Button("Clear All Filters", role: .destructive) {
                    onClear()
                    useStartDate = false
                    useEndDate = false
                    dismiss()
                }
            }
        }
        .navigationTitle("Filter Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    startDate = useStartDate ? tempStartDate : nil
                    endDate = useEndDate ? tempEndDate : nil
                    dismiss()
                }
                .foregroundStyle(Theme.Accent.primary)
            }
        }
        .onAppear {
            if let start = startDate {
                useStartDate = true
                tempStartDate = start
            }
            if let end = endDate {
                useEndDate = true
                tempEndDate = end
            }
        }
    }
}
