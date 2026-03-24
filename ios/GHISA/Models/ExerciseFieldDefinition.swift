import Foundation
import SwiftData

@Model
final class ExerciseFieldDefinition {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise
    var name: String
    var fieldType: String
    var unit: String?
    var selectOptions: [String]?
    var systemKey: String?
    var sortOrder: Int
    var isActive: Bool
    var isDefault: Bool

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSetValue.fieldDefinition)
    var workoutSetValues: [WorkoutSetValue]

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateFieldTarget.fieldDefinition)
    var workoutTemplateFieldTargets: [WorkoutTemplateFieldTarget]

    var createdAt: Date

    init(
        exercise: Exercise,
        name: String,
        fieldType: String,
        unit: String? = nil,
        selectOptions: [String]? = nil,
        systemKey: String? = nil,
        sortOrder: Int,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.name = name
        self.fieldType = fieldType
        self.unit = unit
        self.selectOptions = selectOptions
        self.systemKey = systemKey
        self.sortOrder = sortOrder
        self.isActive = true
        self.isDefault = isDefault
        self.workoutSetValues = []
        self.workoutTemplateFieldTargets = []
        self.createdAt = Date()
    }
}
