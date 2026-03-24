import Foundation
import SwiftData

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var workoutExercise: WorkoutExercise
    var setNumber: Int
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSetValue.workoutSet)
    var values: [WorkoutSetValue]

    @Relationship(deleteRule: .cascade, inverse: \FlagAssignment.workoutSet)
    var flagAssignments: [FlagAssignment]

    var createdAt: Date

    init(workoutExercise: WorkoutExercise, setNumber: Int) {
        self.id = UUID()
        self.workoutExercise = workoutExercise
        self.setNumber = setNumber
        self.values = []
        self.flagAssignments = []
        self.createdAt = Date()
    }
}
