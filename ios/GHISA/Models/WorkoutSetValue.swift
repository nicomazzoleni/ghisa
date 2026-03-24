import Foundation
import SwiftData

@Model
final class WorkoutSetValue {
    @Attribute(.unique) var id: UUID
    var workoutSet: WorkoutSet
    var fieldDefinition: ExerciseFieldDefinition
    var valueNumber: Float?
    var valueText: String?
    var valueToggle: Bool?

    init(
        workoutSet: WorkoutSet,
        fieldDefinition: ExerciseFieldDefinition,
        valueNumber: Float? = nil,
        valueText: String? = nil,
        valueToggle: Bool? = nil
    ) {
        self.id = UUID()
        self.workoutSet = workoutSet
        self.fieldDefinition = fieldDefinition
        self.valueNumber = valueNumber
        self.valueText = valueText
        self.valueToggle = valueToggle
    }
}
