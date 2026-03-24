import Foundation
import SwiftData

@Observable
final class RoutineFormViewModel {
    var name: String = ""
    var notes: String = ""
    var templateExercises: [WorkoutTemplateExercise] = []
    var showingExercisePicker = false
    var errorMessage: String?

    private let templateService: WorkoutTemplateService
    private let user: User
    private var existingTemplate: WorkoutTemplate?

    var isEditing: Bool {
        existingTemplate != nil
    }

    init(templateService: WorkoutTemplateService, user: User, template: WorkoutTemplate? = nil) {
        self.templateService = templateService
        self.user = user
        self.existingTemplate = template
    }

    func loadExisting() {
        guard let template = existingTemplate else { return }
        name = template.name
        notes = template.notes ?? ""
        templateExercises = template.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    func addExercise(_ exercise: Exercise) {
        do {
            if let template = existingTemplate {
                let te = try templateService.addExercise(to: template, exercise: exercise, targetSets: 3)
                templateExercises.append(te)
            } else {
                // For new templates, save first then add
                let template = try templateService.createTemplate(user: user, name: name.isEmpty ? "New Routine" : name)
                existingTemplate = template
                let te = try templateService.addExercise(to: template, exercise: exercise, targetSets: 3)
                templateExercises.append(te)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeExercise(_ templateExercise: WorkoutTemplateExercise) {
        do {
            try templateService.removeExercise(templateExercise)
            templateExercises.removeAll { $0.id == templateExercise.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTargetSets(for templateExercise: WorkoutTemplateExercise, count: Int) {
        templateExercise.targetSets = max(1, count)
        templateExercise.template.updatedAt = Date()
    }

    // MARK: - Reorder

    func moveExerciseUp(_ te: WorkoutTemplateExercise) {
        guard let index = templateExercises.firstIndex(where: { $0.id == te.id }), index > 0 else { return }
        templateExercises.swapAt(index, index - 1)
        applyOrder()
    }

    func moveExerciseDown(_ te: WorkoutTemplateExercise) {
        guard let index = templateExercises.firstIndex(where: { $0.id == te.id }),
              index < templateExercises.count - 1 else { return }
        templateExercises.swapAt(index, index + 1)
        applyOrder()
    }

    private func applyOrder() {
        guard let template = existingTemplate else { return }
        let orderedIDs = templateExercises.map(\.id)
        do {
            try templateService.reorderExercises(template, orderedIDs: orderedIDs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Superset Groups

    func assignSupersetGroup(_ te: WorkoutTemplateExercise, group: Int?) {
        te.supersetGroup = group
        if let template = existingTemplate {
            template.updatedAt = Date()
        }
    }

    func nextAvailableGroup() -> Int {
        let usedGroups = Set(templateExercises.compactMap(\.supersetGroup))
        var next = 1
        while usedGroups.contains(next) {
            next += 1
        }
        return next
    }

    func setFieldTarget(
        for templateExercise: WorkoutTemplateExercise,
        field: ExerciseFieldDefinition,
        number: Float?,
        text: String?
    ) {
        do {
            try templateService.setFieldTarget(
                for: templateExercise,
                fieldDefinition: field,
                targetNumber: number,
                targetText: text
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func save() throws -> WorkoutTemplate {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation(message: "Routine name is required.")
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes: String? = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let template = existingTemplate {
            try templateService.updateTemplate(template, name: trimmedName, notes: trimmedNotes)
            return template
        } else {
            let template = try templateService.createTemplate(user: user, name: trimmedName, notes: trimmedNotes)
            existingTemplate = template
            return template
        }
    }
}
