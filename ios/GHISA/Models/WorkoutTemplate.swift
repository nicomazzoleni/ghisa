import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateExercise.template)
    var exercises: [WorkoutTemplateExercise]

    var createdAt: Date
    var updatedAt: Date

    init(user: User, name: String) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.exercises = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
