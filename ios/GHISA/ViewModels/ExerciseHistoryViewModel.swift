import Foundation
import SwiftData

enum PRType: Hashable {
    case heaviestWeight
    case mostRepsAtWeight
    case bestE1RM
}

struct HistorySet {
    let workoutSet: WorkoutSet
    let setNumber: Int
    var prBadges: Set<PRType> = []
}

struct HistorySession: Identifiable {
    let id: UUID
    let workout: Workout
    let workoutExercise: WorkoutExercise
    let sets: [HistorySet]
    let bestE1RM: Float?

    init(workout: Workout, workoutExercise: WorkoutExercise, sets: [HistorySet], bestE1RM: Float?) {
        self.id = workoutExercise.id
        self.workout = workout
        self.workoutExercise = workoutExercise
        self.sets = sets
        self.bestE1RM = bestE1RM
    }
}

@MainActor
@Observable
final class ExerciseHistoryViewModel {
    let exercise: Exercise
    private(set) var sessions: [HistorySession] = []
    private(set) var currentPRs: [PRType: (set: WorkoutSet, value: Float)] = [:]
    private(set) var chartDataPoints: [(date: Date, e1rm: Float)] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let workoutService: WorkoutService

    func clearError() {
        errorMessage = nil
    }

    var supportsE1RM: Bool {
        hasField(systemKey: "weight") && hasField(systemKey: "reps")
    }

    var supportsWeight: Bool {
        hasField(systemKey: "weight")
    }

    init(exercise: Exercise, workoutService: WorkoutService) {
        self.exercise = exercise
        self.workoutService = workoutService
    }

    func loadHistory(user: User) {
        isLoading = true
        errorMessage = nil

        do {
            let performances = try workoutService.fetchAllPerformances(for: exercise, user: user)
            computeSessions(from: performances)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private

    private func hasField(systemKey: String) -> Bool {
        exercise.fieldDefinitions.contains { $0.systemKey == systemKey }
    }

    private func weightField() -> ExerciseFieldDefinition? {
        exercise.fieldDefinitions.first { $0.systemKey == "weight" }
    }

    private func repsField() -> ExerciseFieldDefinition? {
        exercise.fieldDefinitions.first { $0.systemKey == "reps" }
    }

    private func weightValue(for set: WorkoutSet) -> Float? {
        guard let field = weightField() else { return nil }
        return set.values.first(where: { $0.fieldDefinition.id == field.id })?.valueNumber
    }

    private func repsValue(for set: WorkoutSet) -> Float? {
        guard let field = repsField() else { return nil }
        return set.values.first(where: { $0.fieldDefinition.id == field.id })?.valueNumber
    }

    private func e1rm(weight: Float, reps: Float) -> Float {
        guard reps > 0 else { return weight }
        return weight * (1 + reps / 30)
    }

    private func computeSessions(from performances: [WorkoutExercise]) {
        let allSets = performances.flatMap { workoutExercise in
            workoutExercise.sets.map { ($0, workoutExercise) }
        }

        let detectedPRs = detectPRs(from: allSets.map(\.0))
        currentPRs = detectedPRs

        let prSetMap = buildPRSetMap(from: detectedPRs)
        let (builtSessions, chartPoints) = buildSessions(
            from: performances,
            prSetMap: prSetMap
        )

        sessions = builtSessions
        chartDataPoints = chartPoints.reversed()
    }

    private struct SetRecord {
        let set: WorkoutSet
        let value: Float
    }

    private func detectPRs(from sets: [WorkoutSet]) -> [PRType: (set: WorkoutSet, value: Float)] {
        var prs: [PRType: (set: WorkoutSet, value: Float)] = [:]
        var repsByWeight: [Float: SetRecord] = [:]

        for set in sets {
            if let weight = weightValue(for: set) {
                if weight > (prs[.heaviestWeight]?.value ?? -.infinity) {
                    prs[.heaviestWeight] = (set, weight)
                }
            }

            guard let weight = weightValue(for: set),
                  let reps = repsValue(for: set) else { continue }

            let estimated = e1rm(weight: weight, reps: reps)
            if estimated > (prs[.bestE1RM]?.value ?? -.infinity) {
                prs[.bestE1RM] = (set, estimated)
            }

            if reps > (repsByWeight[weight]?.value ?? -.infinity) {
                repsByWeight[weight] = SetRecord(set: set, value: reps)
            }
        }

        // Best reps across all weight groups
        if let bestReps = repsByWeight.values.max(by: { $0.value < $1.value }) {
            prs[.mostRepsAtWeight] = (bestReps.set, bestReps.value)
        }

        return prs
    }

    private func buildPRSetMap(from prs: [PRType: (set: WorkoutSet, value: Float)]) -> [UUID: Set<PRType>] {
        var map: [UUID: Set<PRType>] = [:]
        for (prType, record) in prs {
            map[record.set.id, default: []].insert(prType)
        }
        return map
    }

    private func buildSessions(
        from performances: [WorkoutExercise],
        prSetMap: [UUID: Set<PRType>]
    ) -> ([HistorySession], [(date: Date, e1rm: Float)]) {
        var builtSessions: [HistorySession] = []
        var chartPoints: [(date: Date, e1rm: Float)] = []

        for workoutExercise in performances {
            let workout = workoutExercise.workout
            let sortedSets = workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }

            var historySets: [HistorySet] = []
            var sessionBestE1RM: Float?

            for set in sortedSets {
                let badges = prSetMap[set.id] ?? []
                historySets.append(HistorySet(
                    workoutSet: set,
                    setNumber: set.setNumber,
                    prBadges: badges
                ))

                if let weight = weightValue(for: set), let reps = repsValue(for: set) {
                    let estimated = e1rm(weight: weight, reps: reps)
                    sessionBestE1RM = max(sessionBestE1RM ?? -.infinity, estimated)
                }
            }

            builtSessions.append(HistorySession(
                workout: workout,
                workoutExercise: workoutExercise,
                sets: historySets,
                bestE1RM: sessionBestE1RM
            ))

            if let best = sessionBestE1RM {
                chartPoints.append((workout.date, best))
            }
        }

        return (builtSessions, chartPoints)
    }
}
