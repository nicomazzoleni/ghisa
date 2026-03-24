import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var muscleGroups: [String]
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \ExerciseFieldDefinition.exercise)
    var fieldDefinitions: [ExerciseFieldDefinition]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutTemplateExercise.exercise)
    var workoutTemplateExercises: [WorkoutTemplateExercise]

    var createdAt: Date
    var updatedAt: Date

    init(
        user: User,
        name: String,
        muscleGroups: [String] = []
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.muscleGroups = muscleGroups
        self.isArchived = false
        self.fieldDefinitions = []
        self.workoutExercises = []
        self.workoutTemplateExercises = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
