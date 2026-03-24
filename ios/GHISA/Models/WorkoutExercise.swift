import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var workout: Workout
    var exercise: Exercise?
    var sortOrder: Int
    var supersetGroup: Int?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet]

    @Relationship(deleteRule: .cascade, inverse: \FlagAssignment.workoutExercise)
    var flagAssignments: [FlagAssignment]

    var createdAt: Date

    init(
        workout: Workout,
        exercise: Exercise,
        sortOrder: Int,
        supersetGroup: Int? = nil
    ) {
        self.id = UUID()
        self.workout = workout
        self.exercise = exercise
        self.sortOrder = sortOrder
        self.supersetGroup = supersetGroup
        self.sets = []
        self.flagAssignments = []
        self.createdAt = Date()
    }
}
