import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var user: User
    var status: String
    var date: Date
    var startedAt: Date?
    var endedAt: Date?
    var durationMinutes: Int?
    var notes: String?
    var location: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var workoutExercises: [WorkoutExercise]

    @Relationship(deleteRule: .cascade, inverse: \FlagAssignment.workout)
    var flagAssignments: [FlagAssignment]

    var createdAt: Date
    var updatedAt: Date

    init(user: User, date: Date = .now) {
        self.id = UUID()
        self.user = user
        self.status = "in_progress"
        self.date = date
        self.workoutExercises = []
        self.flagAssignments = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
