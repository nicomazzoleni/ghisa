import Foundation
import SwiftData

// MARK: - Training Data Seeder

extension DataSeedService {
    /// Check if seeded training data already exists.
    func hasSeededTrainingData() throws -> Bool {
        let names = TrainingSeedConfig.seededExerciseNames
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                names.contains(exercise.name)
            }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }

    /// Delete all seeded exercises and their cascaded workouts/sets.
    func clearTrainingData() throws {
        let names = TrainingSeedConfig.seededExerciseNames
        let exerciseDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                names.contains(exercise.name)
            }
        )
        let exercises = try modelContext.fetch(exerciseDescriptor)
        for exercise in exercises {
            modelContext.delete(exercise)
        }

        // Also delete any workouts that now have zero exercises (orphaned by cascade nullify)
        let workoutDescriptor = FetchDescriptor<Workout>()
        let workouts = try modelContext.fetch(workoutDescriptor)
        for workout in workouts where workout.workoutExercises.isEmpty {
            modelContext.delete(workout)
        }

        try modelContext.save()
    }

    private struct SessionState {
        var sessionCountA = 0
        var sessionCountB = 0
        var sessionsSinceDeload = 0
        let totalA: Int
        let totalB: Int
    }

    /// Generate 1 year of realistic training data. Returns the number of workouts created.
    @MainActor
    func seedTrainingData() async throws -> Int {
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try modelContext.fetch(userDescriptor).first else {
            throw AppError.validation(message: "No user found. Run initial seed first.")
        }

        let exerciseMap = createSeederExercises(for: user)
        let schedule = generateSchedule()
        let deloadWeeks = computeDeloadWeeks()

        var state = SessionState(
            totalA: schedule.count(where: { $0.day == "A" }),
            totalB: schedule.count(where: { $0.day == "B" })
        )

        var workoutCount = 0

        for (index, session) in schedule.enumerated() {
            let isDeload = deloadWeeks.contains(session.week)
            createWorkout(user: user, session: session, isDeload: isDeload, exerciseMap: exerciseMap, state: &state)

            if session.day == "A" { state.sessionCountA += 1 } else { state.sessionCountB += 1 }
            state.sessionsSinceDeload += 1
            if isDeload, session.day == "B" { state.sessionsSinceDeload = 0 }
            workoutCount += 1

            if index % 10 == 0 { await Task.yield() }
        }

        try modelContext.save()
        return workoutCount
    }

    private func createWorkout(
        user: User,
        session: ScheduleEntry,
        isDeload: Bool,
        exerciseMap: [String: (Exercise, [String: ExerciseFieldDefinition])],
        state: inout SessionState
    ) {
        let workout = Workout(user: user, date: session.date)
        workout.status = "completed"

        let hour = Int.random(in: 6 ... 18)
        let minutes = [0, 15, 30, 45]
        let minute = minutes[Int.random(in: 0 ..< minutes.count)]
        if let startedAt = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: session.date) {
            let duration = Int.random(in: 45 ... 75)
            workout.startedAt = startedAt
            workout.endedAt = startedAt.addingTimeInterval(Double(duration * 60))
            workout.durationMinutes = duration
        }

        modelContext.insert(workout)

        let configs = TrainingSeedConfig.exerciseConfigs.filter { $0.day == session.day }
        let sessionIndex = session.day == "A" ? state.sessionCountA : state.sessionCountB
        let totalSessions = session.day == "A" ? state.totalA : state.totalB

        for (sortOrder, config) in configs.enumerated() {
            guard let (exercise, fields) = exerciseMap[config.name] else { continue }
            populateExercise(
                workout: workout, exercise: exercise, fields: fields, config: config,
                sortOrder: sortOrder, sessionIndex: sessionIndex, totalSessions: totalSessions,
                isDeload: isDeload, sessionsSinceDeload: state.sessionsSinceDeload
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func populateExercise(
        workout: Workout, exercise: Exercise,
        fields: [String: ExerciseFieldDefinition], config: TrainingSeedConfig.ExerciseConfig,
        sortOrder: Int, sessionIndex: Int, totalSessions: Int,
        isDeload: Bool, sessionsSinceDeload: Int
    ) {
        let workoutExercise = WorkoutExercise(workout: workout, exercise: exercise, sortOrder: sortOrder)
        modelContext.insert(workoutExercise)

        let setCount = isDeload ? max(config.defaultSets - 1, 2) : config.defaultSets
        let isBadSession = !isDeload && Float.random(in: 0 ... 1) < 0.1

        for setNum in 1 ... setCount {
            let set = WorkoutSet(workoutExercise: workoutExercise, setNumber: setNum)
            modelContext.insert(set)

            if config.hasWeight {
                seedBarbellSet(
                    set: set,
                    fields: fields,
                    config: config,
                    setNum: setNum,
                    setCount: setCount,
                    sessionIndex: sessionIndex,
                    totalSessions: totalSessions,
                    isDeload: isDeload,
                    isBadSession: isBadSession
                )
            } else {
                seedBodyweightSet(
                    set: set,
                    fields: fields,
                    config: config,
                    setNum: setNum,
                    setCount: setCount,
                    sessionIndex: sessionIndex,
                    totalSessions: totalSessions
                )
            }

            let rpe = computeRPE(sessionsSinceDeload: sessionsSinceDeload, isDeload: isDeload)
            if let rpeField = fields["rpe"] {
                modelContext.insert(WorkoutSetValue(workoutSet: set, fieldDefinition: rpeField, valueNumber: rpe))
            }
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func seedBarbellSet(
        set: WorkoutSet, fields: [String: ExerciseFieldDefinition], config: TrainingSeedConfig.ExerciseConfig,
        setNum: Int, setCount: Int, sessionIndex: Int, totalSessions: Int,
        isDeload: Bool, isBadSession: Bool
    ) {
        let weight = computeWeight(
            session: sessionIndex, total: totalSessions,
            start: config.startWeight, target: config.targetWeight,
            isDeload: isDeload, isBadSession: isBadSession
        )
        if let weightField = fields["weight"] {
            modelContext.insert(WorkoutSetValue(workoutSet: set, fieldDefinition: weightField, valueNumber: weight))
        }

        var reps = config.defaultReps
        if isBadSession, setNum >= setCount - 1 {
            reps = max(reps - Int.random(in: 1 ... 2), 1)
        } else if !isDeload, Float.random(in: 0 ... 1) < 0.15 {
            reps = config.defaultReps == 5 ? 8 : 6
        }
        if let repsField = fields["reps"] {
            modelContext.insert(WorkoutSetValue(workoutSet: set, fieldDefinition: repsField, valueNumber: Float(reps)))
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func seedBodyweightSet(
        set: WorkoutSet, fields: [String: ExerciseFieldDefinition], config: TrainingSeedConfig.ExerciseConfig,
        setNum: Int, setCount: Int, sessionIndex: Int, totalSessions: Int
    ) {
        let baseReps = computePullUpReps(
            session: sessionIndex, total: totalSessions,
            start: config.startReps, target: config.targetReps
        )
        let fatigueDrop = setNum == setCount ? Int.random(in: 1 ... 2) : 0
        let noise = Int.random(in: -1 ... 1)
        let reps = max(baseReps + noise - fatigueDrop, 3)
        if let repsField = fields["reps"] {
            modelContext.insert(WorkoutSetValue(workoutSet: set, fieldDefinition: repsField, valueNumber: Float(reps)))
        }
    }

    // MARK: - Private Helpers

    private struct ScheduleEntry {
        let date: Date
        let day: String // "A" or "B"
        let week: Int // 0-based week number
    }

    private func generateSchedule() -> [ScheduleEntry] {
        let calendar = Calendar.current
        let today = Date()
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) else { return [] }

        // Find the Monday of the week containing oneYearAgo
        var startMonday = oneYearAgo
        while calendar.component(.weekday, from: startMonday) != 2 { // 2 = Monday
            guard let next = calendar.date(byAdding: .day, value: 1, to: startMonday) else { return [] }
            startMonday = next
        }

        var entries: [ScheduleEntry] = []

        for week in 0 ..< 52 {
            guard let monday = calendar.date(byAdding: .weekOfYear, value: week, to: startMonday),
                  let thursday = calendar.date(byAdding: .day, value: 3, to: monday)
            else { continue }

            // Skip if in the future
            if monday > today, thursday > today { continue }

            // Day A (Monday) — ~5% skip chance, ~10% day shift
            if monday <= today, Float.random(in: 0 ... 1) > 0.05 {
                var dayA = monday
                if Float.random(in: 0 ... 1) < 0.1 {
                    let shift = Bool.random() ? 1 : -1
                    dayA = calendar.date(byAdding: .day, value: shift, to: monday) ?? monday
                }
                entries.append(ScheduleEntry(date: dayA, day: "A", week: week))
            }

            // Day B (Thursday) — ~5% skip chance, ~10% day shift
            if thursday <= today, Float.random(in: 0 ... 1) > 0.05 {
                var dayB = thursday
                if Float.random(in: 0 ... 1) < 0.1 {
                    let shift = Bool.random() ? 1 : -1
                    dayB = calendar.date(byAdding: .day, value: shift, to: thursday) ?? thursday
                }
                entries.append(ScheduleEntry(date: dayB, day: "B", week: week))
            }
        }

        return entries.sorted { $0.date < $1.date }
    }

    private func computeDeloadWeeks() -> Set<Int> {
        var deloads = Set<Int>()
        var week = Int.random(in: 5 ... 6)
        while week < 52 {
            deloads.insert(week)
            week += Int.random(in: 5 ... 6)
        }
        return deloads
    }

    // Logarithmic progression with noise, snapped to 1.25 kg.
    // swiftlint:disable:next function_parameter_count
    private func computeWeight(
        session: Int, total: Int,
        start: Float, target: Float,
        isDeload: Bool, isBadSession: Bool
    ) -> Float {
        let curveFactor: Float = 4.0
        let sessionFloat = Float(session)
        let totalFloat = Float(max(total, 1))

        let base = start + (target - start) * log(1 + curveFactor * sessionFloat) / log(1 + curveFactor * totalFloat)

        var weight = base

        // Noise: ±2.5 kg
        weight += Float.random(in: -2.5 ... 2.5)

        if isBadSession {
            weight -= Float.random(in: 5.0 ... 7.5)
        }

        if isDeload {
            weight = base * Float.random(in: 0.70 ... 0.80)
        }

        // Snap to nearest 1.25 kg
        weight = (weight / 1.25).rounded() * 1.25

        return max(weight, 20.0) // Floor at 20 kg (empty barbell)
    }

    /// Pull-ups: linear reps progression with noise.
    private func computePullUpReps(session: Int, total: Int, start: Int, target: Int) -> Int {
        let progress = Float(session) / Float(max(total, 1))
        let base = Float(start) + Float(target - start) * progress
        return max(Int(base.rounded()), 3)
    }

    /// RPE model: creeps up between deloads, drops during deload.
    private func computeRPE(sessionsSinceDeload: Int, isDeload: Bool) -> Float {
        if isDeload {
            let raw = Float.random(in: 5.0 ... 6.0)
            return (raw * 2).rounded() / 2 // Round to 0.5
        }
        let base: Float = 7.0 + Float(sessionsSinceDeload) * 0.15
        let clamped = min(max(base, 7.0), 8.5)
        let noisy = clamped + Float.random(in: -0.3 ... 0.3)
        return (noisy * 2).rounded() / 2 // Round to 0.5
    }

    /// Create the 6 exercises with field definitions. Returns map: name -> (Exercise, fieldKey -> FieldDefinition).
    private func createSeederExercises(for user: User) -> [String: (Exercise, [String: ExerciseFieldDefinition])] {
        var result: [String: (Exercise, [String: ExerciseFieldDefinition])] = [:]

        for config in TrainingSeedConfig.exerciseConfigs {
            let exercise = Exercise(user: user, name: config.name, muscleGroups: config.muscleGroups)
            modelContext.insert(exercise)

            var fields: [String: ExerciseFieldDefinition] = [:]

            // Reps field (always present)
            let repsField = ExerciseFieldDefinition(
                exercise: exercise, name: "Reps", fieldType: "number",
                systemKey: "reps", sortOrder: 0, isDefault: true
            )
            modelContext.insert(repsField)
            fields["reps"] = repsField

            if config.hasWeight {
                // Weight field
                let weightField = ExerciseFieldDefinition(
                    exercise: exercise, name: "Weight", fieldType: "number",
                    unit: "kg", systemKey: "weight", sortOrder: 1, isDefault: true
                )
                modelContext.insert(weightField)
                fields["weight"] = weightField

                // RPE field
                let rpeField = ExerciseFieldDefinition(
                    exercise: exercise, name: "RPE", fieldType: "number",
                    systemKey: "rpe", sortOrder: 2, isDefault: true
                )
                modelContext.insert(rpeField)
                fields["rpe"] = rpeField
            } else {
                // Pull-ups: RPE at sortOrder 1 (no weight)
                let rpeField = ExerciseFieldDefinition(
                    exercise: exercise, name: "RPE", fieldType: "number",
                    systemKey: "rpe", sortOrder: 1, isDefault: true
                )
                modelContext.insert(rpeField)
                fields["rpe"] = rpeField
            }

            result[config.name] = (exercise, fields)
        }

        return result
    }
}
