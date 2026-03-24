import Foundation
import SwiftData

@Observable
final class ExerciseDetailViewModel {
    var exercise: Exercise
    var showArchiveConfirmation: Bool = false
    var errorMessage: String?

    private let service: ExerciseService

    init(service: ExerciseService, exercise: Exercise) {
        self.service = service
        self.exercise = exercise
    }

    var sortedFields: [ExerciseFieldDefinition] {
        exercise.fieldDefinitions.sorted { $0.sortOrder < $1.sortOrder }
    }

    func archiveExercise() {
        do {
            try service.archiveExercise(exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreExercise() {
        do {
            try service.restoreExercise(exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFieldActive(_ field: ExerciseFieldDefinition) {
        do {
            try service.toggleFieldActive(field)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveFieldUp(_ field: ExerciseFieldDefinition) {
        var fields = sortedFields
        guard let index = fields.firstIndex(where: { $0.id == field.id }), index > 0 else { return }
        fields.swapAt(index, index - 1)
        do {
            try service.reorderFields(exercise, orderedIDs: fields.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveFieldDown(_ field: ExerciseFieldDefinition) {
        var fields = sortedFields
        guard let index = fields.firstIndex(where: { $0.id == field.id }), index < fields.count - 1 else { return }
        fields.swapAt(index, index + 1)
        do {
            try service.reorderFields(exercise, orderedIDs: fields.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCustomField(
        name: String,
        fieldType: String,
        unit: String?,
        selectOptions: [String]?
    ) {
        do {
            _ = try service.addCustomField(
                to: exercise,
                name: name,
                fieldType: fieldType,
                unit: unit,
                selectOptions: selectOptions
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
