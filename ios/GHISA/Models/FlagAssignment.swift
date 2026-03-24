import Foundation
import SwiftData

@Model
final class FlagAssignment {
    @Attribute(.unique) var id: UUID
    var flag: Flag
    var workout: Workout?
    var workoutExercise: WorkoutExercise?
    var workoutSet: WorkoutSet?
    var createdAt: Date

    init(
        flag: Flag,
        workout: Workout? = nil,
        workoutExercise: WorkoutExercise? = nil,
        workoutSet: WorkoutSet? = nil
    ) {
        self.id = UUID()
        self.flag = flag
        self.workout = workout
        self.workoutExercise = workoutExercise
        self.workoutSet = workoutSet
        self.createdAt = Date()
    }
}
