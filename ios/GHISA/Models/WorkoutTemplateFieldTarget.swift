import Foundation
import SwiftData

@Model
final class WorkoutTemplateFieldTarget {
    @Attribute(.unique) var id: UUID
    var templateExercise: WorkoutTemplateExercise
    var fieldDefinition: ExerciseFieldDefinition
    var targetValueNumber: Float?
    var targetValueText: String?

    init(
        templateExercise: WorkoutTemplateExercise,
        fieldDefinition: ExerciseFieldDefinition,
        targetValueNumber: Float? = nil,
        targetValueText: String? = nil
    ) {
        self.id = UUID()
        self.templateExercise = templateExercise
        self.fieldDefinition = fieldDefinition
        self.targetValueNumber = targetValueNumber
        self.targetValueText = targetValueText
    }
}
