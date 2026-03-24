import Foundation
import SwiftData

@Observable
final class WorkoutService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Start / Resume

    func startWorkout(user: User) throws -> Workout {
        if try fetchInProgressWorkout(for: user) != nil {
            throw AppError.validation(message: "A workout is already in progress.")
        }

        let workout = Workout(user: user, date: .now)
        workout.startedAt = .now
        modelContext.insert(workout)
        try modelContext.save()
        return workout
    }

    func fetchInProgressWorkout(for user: User) throws -> Workout? {
        let userId = user.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.user.id == userId && workout.status == "in_progress"
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Exercises

    func addExercise(to workout: Workout, exercise: Exercise) throws -> WorkoutExercise {
        let sortOrder = workout.workoutExercises.count
        let workoutExercise = WorkoutExercise(
            workout: workout,
            exercise: exercise,
            sortOrder: sortOrder
        )
        modelContext.insert(workoutExercise)

        // Auto-add first empty set
        let firstSet = try addSet(to: workoutExercise)
        _ = firstSet

        try modelContext.save()
        return workoutExercise
    }

    func removeExercise(_ workoutExercise: WorkoutExercise) throws {
        let workout = workoutExercise.workout
        modelContext.delete(workoutExercise)

        // Renumber remaining exercises
        let sorted = workout.workoutExercises
            .filter { $0.id != workoutExercise.id }
            .sorted { $0.sortOrder < $1.sortOrder }
        for (index, we) in sorted.enumerated() {
            we.sortOrder = index
        }

        try modelContext.save()
    }

    // MARK: - Sets

    func addSet(to workoutExercise: WorkoutExercise) throws -> WorkoutSet {
        let setNumber = workoutExercise.sets.count + 1
        let set = WorkoutSet(workoutExercise: workoutExercise, setNumber: setNumber)
        modelContext.insert(set)

        // Pre-create a WorkoutSetValue for each active field definition
        let activeFields = (workoutExercise.exercise?.fieldDefinitions ?? [])
            .filter(\.isActive)
            .sorted { $0.sortOrder < $1.sortOrder }

        for field in activeFields {
            let value = WorkoutSetValue(workoutSet: set, fieldDefinition: field)
            modelContext.insert(value)
        }

        try modelContext.save()
        return set
    }

    func removeSet(_ set: WorkoutSet) throws {
        let workoutExercise = set.workoutExercise
        modelContext.delete(set)

        // Renumber remaining sets
        let sorted = workoutExercise.sets
            .filter { $0.id != set.id }
            .sorted { $0.setNumber < $1.setNumber }
        for (index, remainingSet) in sorted.enumerated() {
            remainingSet.setNumber = index + 1
        }

        try modelContext.save()
    }

    // MARK: - Values

    func updateSetValue(
        _ value: WorkoutSetValue,
        number: Float? = nil,
        text: String? = nil,
        toggle: Bool? = nil
    ) throws {
        value.valueNumber = number
        value.valueText = text
        value.valueToggle = toggle
        try modelContext.save()
    }

    // MARK: - Finish / Discard

    func finishWorkout(_ workout: Workout) throws {
        workout.status = "completed"
        workout.endedAt = .now
        if let start = workout.startedAt {
            workout.durationMinutes = Int(Date.now.timeIntervalSince(start) / 60)
        }
        workout.updatedAt = Date()
        try modelContext.save()
    }

    func discardWorkout(_ workout: Workout) throws {
        workout.status = "discarded"
        workout.endedAt = .now
        workout.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Fetch

    func fetchCompletedWorkouts(for user: User, limit: Int = 20) throws -> [Workout] {
        let userId = user.id
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.user.id == userId && workout.status == "completed"
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Notes

    func updateWorkoutNotes(_ workout: Workout, notes: String?) throws {
        workout.notes = notes
        workout.updatedAt = Date()
        try modelContext.save()
    }

    func updateSetNotes(_ set: WorkoutSet, notes: String?) throws {
        set.notes = notes
        try modelContext.save()
    }

    // MARK: - Date / Location

    func updateWorkoutDate(_ workout: Workout, date: Date) throws {
        workout.date = date
        workout.updatedAt = Date()
        try modelContext.save()
    }

    func updateWorkoutLocation(_ workout: Workout, location: String?) throws {
        workout.location = location
        workout.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Reorder

    func reorderExercises(_ workout: Workout, orderedIDs: [UUID]) throws {
        for (index, id) in orderedIDs.enumerated() {
            if let exercise = workout.workoutExercises.first(where: { $0.id == id }) {
                exercise.sortOrder = index
            }
        }
        workout.updatedAt = Date()
        try modelContext.save()
    }

    func reorderSets(in workoutExercise: WorkoutExercise, orderedIDs: [UUID]) throws {
        for (index, id) in orderedIDs.enumerated() {
            if let set = workoutExercise.sets.first(where: { $0.id == id }) {
                set.setNumber = index + 1
            }
        }
        try modelContext.save()
    }

    // MARK: - Start from Template

    func startWorkoutFromTemplate(user: User, template: WorkoutTemplate) throws -> Workout {
        if try fetchInProgressWorkout(for: user) != nil {
            throw AppError.validation(message: "A workout is already in progress.")
        }

        let workout = Workout(user: user, date: .now)
        workout.startedAt = .now
        modelContext.insert(workout)

        let sortedTemplateExercises = template.exercises.sorted { $0.sortOrder < $1.sortOrder }
        for templateExercise in sortedTemplateExercises {
            guard let exercise = templateExercise.exercise else { continue }

            let workoutExercise = WorkoutExercise(
                workout: workout,
                exercise: exercise,
                sortOrder: templateExercise.sortOrder,
                supersetGroup: templateExercise.supersetGroup
            )
            modelContext.insert(workoutExercise)

            let lastPerformance = try fetchLastPerformance(for: exercise, user: user)
            let lastSets = lastPerformance?.sets.sorted { $0.setNumber < $1.setNumber } ?? []
            let targetSetCount = templateExercise.targetSets ?? 1

            for setIndex in 0 ..< targetSetCount {
                let setNumber = setIndex + 1
                let set = WorkoutSet(workoutExercise: workoutExercise, setNumber: setNumber)
                modelContext.insert(set)

                let activeFields = (exercise.fieldDefinitions)
                    .filter(\.isActive)
                    .sorted { $0.sortOrder < $1.sortOrder }

                for field in activeFields {
                    let value = WorkoutSetValue(workoutSet: set, fieldDefinition: field)

                    // Smart pre-fill: prefer last performance, then template targets
                    let lastValue = setIndex < lastSets.count
                        ? lastSets[setIndex].values.first(where: { $0.fieldDefinition.id == field.id })
                        : nil
                    let targetValue = templateExercise.fieldTargets.first(where: { $0.fieldDefinition.id == field.id })

                    if let lastValue {
                        value.valueNumber = lastValue.valueNumber
                        value.valueText = lastValue.valueText
                        value.valueToggle = lastValue.valueToggle
                    } else if let targetValue {
                        value.valueNumber = targetValue.targetValueNumber
                        value.valueText = targetValue.targetValueText
                    }

                    modelContext.insert(value)
                }
            }
        }

        try modelContext.save()
        return workout
    }

    // MARK: - Copy Workout

    func copyWorkout(user: User, source: Workout) throws -> Workout {
        if try fetchInProgressWorkout(for: user) != nil {
            throw AppError.validation(message: "A workout is already in progress.")
        }

        let workout = Workout(user: user, date: .now)
        workout.startedAt = .now
        modelContext.insert(workout)

        let sortedExercises = source.workoutExercises.sorted { $0.sortOrder < $1.sortOrder }
        for sourceExercise in sortedExercises {
            guard let exercise = sourceExercise.exercise else { continue }

            let workoutExercise = WorkoutExercise(
                workout: workout,
                exercise: exercise,
                sortOrder: sourceExercise.sortOrder,
                supersetGroup: sourceExercise.supersetGroup
            )
            modelContext.insert(workoutExercise)

            let sourceSets = sourceExercise.sets.sorted { $0.setNumber < $1.setNumber }
            for sourceSet in sourceSets {
                let set = WorkoutSet(workoutExercise: workoutExercise, setNumber: sourceSet.setNumber)
                modelContext.insert(set)

                for sourceValue in sourceSet.values {
                    let value = WorkoutSetValue(
                        workoutSet: set,
                        fieldDefinition: sourceValue.fieldDefinition,
                        valueNumber: sourceValue.valueNumber,
                        valueText: sourceValue.valueText,
                        valueToggle: sourceValue.valueToggle
                    )
                    modelContext.insert(value)
                }
            }
        }

        try modelContext.save()
        return workout
    }

    // MARK: - Last Performance

    func fetchAllPerformances(for exercise: Exercise, user: User) throws -> [WorkoutExercise] {
        let userId = user.id
        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.user.id == userId && workout.status == "completed"
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let workouts = try modelContext.fetch(descriptor)

        return workouts.compactMap { workout in
            workout.workoutExercises.first(where: { $0.exercise?.id == exerciseId })
        }
    }

    func fetchLastPerformance(for exercise: Exercise, user: User) throws -> WorkoutExercise? {
        let userId = user.id
        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.user.id == userId && workout.status == "completed"
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let workouts = try modelContext.fetch(descriptor)

        for workout in workouts {
            if let match = workout.workoutExercises.first(where: { $0.exercise?.id == exerciseId }) {
                return match
            }
        }
        return nil
    }
}
