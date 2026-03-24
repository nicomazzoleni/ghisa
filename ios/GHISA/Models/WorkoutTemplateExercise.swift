import Foundation
import SwiftData

@Model
final class WorkoutTemplateExercise {
    @Attribute(.unique) var id: UUID
    var template: WorkoutTemplate
    var exercise: Exercise?
    var sortOrder: Int
    var supersetGroup: Int?
    var targetSets: Int?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateFieldTarget.templateExercise)
    var fieldTargets: [WorkoutTemplateFieldTarget]

    init(
        template: WorkoutTemplate,
        exercise: Exercise,
        sortOrder: Int,
        supersetGroup: Int? = nil,
        targetSets: Int? = nil
    ) {
        self.id = UUID()
        self.template = template
        self.exercise = exercise
        self.sortOrder = sortOrder
        self.supersetGroup = supersetGroup
        self.targetSets = targetSets
        self.fieldTargets = []
    }
}
