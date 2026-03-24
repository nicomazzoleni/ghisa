import Foundation
import SwiftData

@MainActor
@Observable
final class ActiveWorkoutViewModel {
    var workout: Workout
    var elapsedSeconds: Int = 0
    var showingDiscardConfirmation = false
    var showingFinishConfirmation = false
    var showingExercisePicker = false
    var showingFlagPicker = false
    var showingSaveAsRoutine = false
    var saveAsRoutineName = ""
    var flagPickerTarget: FlagPickerTarget?
    var showingExerciseHistory = false
    var exerciseForHistory: Exercise?
    var errorMessage: String?

    private let workoutService: WorkoutService
    private let flagService: FlagService
    private let templateService: WorkoutTemplateService?
    private var timerTask: Task<Void, Never>?

    enum FlagPickerTarget {
        case workout
        case exercise(WorkoutExercise)
        case set(WorkoutSet)
    }

    init(
        workout: Workout,
        workoutService: WorkoutService,
        flagService: FlagService,
        templateService: WorkoutTemplateService? = nil
    ) {
        self.workout = workout
        self.workoutService = workoutService
        self.flagService = flagService
        self.templateService = templateService

        if let start = workout.startedAt {
            self.elapsedSeconds = Int(Date.now.timeIntervalSince(start))
        }
    }

    // MARK: - Timer

    func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let start = workout.startedAt else { return }
                elapsedSeconds = Int(Date.now.timeIntervalSince(start))
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    var formattedElapsedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Sorted Data

    var sortedExercises: [WorkoutExercise] {
        workout.workoutExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Exercise Actions

    func addExercise(_ exercise: Exercise) {
        do {
            _ = try workoutService.addExercise(to: workout, exercise: exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeExercise(_ workoutExercise: WorkoutExercise) {
        do {
            try workoutService.removeExercise(workoutExercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Set Actions

    func addSet(to workoutExercise: WorkoutExercise) {
        do {
            _ = try workoutService.addSet(to: workoutExercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeSet(_ set: WorkoutSet) {
        do {
            try workoutService.removeSet(set)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Value Updates

    func updateValue(_ value: WorkoutSetValue, number: Float?, text: String?, toggle: Bool?) {
        do {
            try workoutService.updateSetValue(value, number: number, text: text, toggle: toggle)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Notes

    func updateNotes(_ notes: String) {
        do {
            let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            try workoutService.updateWorkoutNotes(workout, notes: trimmed.isEmpty ? nil : trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSetNotes(_ set: WorkoutSet, notes: String?) {
        do {
            try workoutService.updateSetNotes(set, notes: notes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Date / Location

    func updateWorkoutDate(_ date: Date) {
        do {
            try workoutService.updateWorkoutDate(workout, date: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateLocation(_ location: String?) {
        do {
            try workoutService.updateWorkoutLocation(workout, location: location)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reorder

    func moveExerciseUp(_ exercise: WorkoutExercise) {
        var ordered = sortedExercises
        guard let index = ordered.firstIndex(where: { $0.id == exercise.id }), index > 0 else { return }
        ordered.swapAt(index, index - 1)
        do {
            try workoutService.reorderExercises(workout, orderedIDs: ordered.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveExerciseDown(_ exercise: WorkoutExercise) {
        var ordered = sortedExercises
        guard let index = ordered.firstIndex(where: { $0.id == exercise.id }), index < ordered.count - 1 else { return }
        ordered.swapAt(index, index + 1)
        do {
            try workoutService.reorderExercises(workout, orderedIDs: ordered.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveSetUp(in workoutExercise: WorkoutExercise, set: WorkoutSet) {
        var ordered = workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }
        guard let index = ordered.firstIndex(where: { $0.id == set.id }), index > 0 else { return }
        ordered.swapAt(index, index - 1)
        do {
            try workoutService.reorderSets(in: workoutExercise, orderedIDs: ordered.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveSetDown(in workoutExercise: WorkoutExercise, set: WorkoutSet) {
        var ordered = workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }
        guard let index = ordered.firstIndex(where: { $0.id == set.id }), index < ordered.count - 1 else { return }
        ordered.swapAt(index, index + 1)
        do {
            try workoutService.reorderSets(in: workoutExercise, orderedIDs: ordered.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Superset Groups

    func assignSupersetGroup(_ exercise: WorkoutExercise, group: Int?) {
        exercise.supersetGroup = group
        workout.updatedAt = Date()
    }

    func nextAvailableGroup() -> Int {
        let usedGroups = Set(workout.workoutExercises.compactMap(\.supersetGroup))
        var next = 1
        while usedGroups.contains(next) {
            next += 1
        }
        return next
    }

    // MARK: - Flags

    func showFlagPicker(for target: FlagPickerTarget) {
        flagPickerTarget = target
        showingFlagPicker = true
    }

    var flagPickerScope: String {
        switch flagPickerTarget {
            case .workout: "workout"
            case .exercise: "exercise"
            case .set: "set"
            case .none: "workout"
        }
    }

    var flagPickerAssignments: [FlagAssignment] {
        switch flagPickerTarget {
            case .workout: workout.flagAssignments
            case let .exercise(we): we.flagAssignments
            case let .set(ws): ws.flagAssignments
            case .none: []
        }
    }

    func assignFlag(_ flag: Flag) {
        do {
            switch flagPickerTarget {
                case .workout:
                    _ = try flagService.assignFlag(flag, to: workout)
                case let .exercise(we):
                    _ = try flagService.assignFlag(flag, to: we)
                case let .set(ws):
                    _ = try flagService.assignFlag(flag, to: ws)
                case .none:
                    break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAssignment(_ assignment: FlagAssignment) {
        do {
            try flagService.removeAssignment(assignment)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func availableFlags(for scope: String) -> [Flag] {
        flagService.fetchFlags(for: workout.user, scope: scope)
    }

    // MARK: - Finish / Discard

    func finishWorkout() throws {
        stopTimer()
        try workoutService.finishWorkout(workout)
        if templateService != nil {
            showingSaveAsRoutine = true
        }
    }

    func saveAsRoutine(name: String) {
        guard let templateService else { return }
        do {
            _ = try templateService.createTemplate(from: workout, user: workout.user, name: name)
        } catch {
            errorMessage = error.localizedDescription
        }
        showingSaveAsRoutine = false
    }

    func skipSaveAsRoutine() {
        showingSaveAsRoutine = false
    }

    func discardWorkout() throws {
        stopTimer()
        try workoutService.discardWorkout(workout)
    }
}
