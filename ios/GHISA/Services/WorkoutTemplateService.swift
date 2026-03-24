import Foundation
import SwiftData

@Observable
final class WorkoutTemplateService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Template CRUD

    func createTemplate(user: User, name: String, notes: String? = nil) throws -> WorkoutTemplate {
        let template = WorkoutTemplate(user: user, name: name)
        template.notes = notes
        modelContext.insert(template)
        try modelContext.save()
        return template
    }

    func fetchTemplates(for user: User) throws -> [WorkoutTemplate] {
        let userId = user.id
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate<WorkoutTemplate> { template in
                template.user.id == userId
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func updateTemplate(_ template: WorkoutTemplate, name: String, notes: String?) throws {
        template.name = name
        template.notes = notes
        template.updatedAt = Date()
        try modelContext.save()
    }

    func deleteTemplate(_ template: WorkoutTemplate) throws {
        modelContext.delete(template)
        try modelContext.save()
    }

    // MARK: - Template Exercises

    func addExercise(
        to template: WorkoutTemplate,
        exercise: Exercise,
        targetSets: Int? = nil
    ) throws -> WorkoutTemplateExercise {
        let sortOrder = template.exercises.count
        let templateExercise = WorkoutTemplateExercise(
            template: template,
            exercise: exercise,
            sortOrder: sortOrder,
            targetSets: targetSets
        )
        modelContext.insert(templateExercise)
        template.updatedAt = Date()
        try modelContext.save()
        return templateExercise
    }

    func removeExercise(_ templateExercise: WorkoutTemplateExercise) throws {
        let template = templateExercise.template
        modelContext.delete(templateExercise)

        // Renumber remaining exercises
        let sorted = template.exercises
            .filter { $0.id != templateExercise.id }
            .sorted { $0.sortOrder < $1.sortOrder }
        for (index, te) in sorted.enumerated() {
            te.sortOrder = index
        }

        template.updatedAt = Date()
        try modelContext.save()
    }

    func reorderExercises(_ template: WorkoutTemplate, orderedIDs: [UUID]) throws {
        for (index, id) in orderedIDs.enumerated() {
            if let exercise = template.exercises.first(where: { $0.id == id }) {
                exercise.sortOrder = index
            }
        }
        template.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Field Targets

    func setFieldTarget(
        for templateExercise: WorkoutTemplateExercise,
        fieldDefinition: ExerciseFieldDefinition,
        targetNumber: Float? = nil,
        targetText: String? = nil
    ) throws {
        if let existing = templateExercise.fieldTargets.first(where: { $0.fieldDefinition.id == fieldDefinition.id }) {
            existing.targetValueNumber = targetNumber
            existing.targetValueText = targetText
        } else {
            let target = WorkoutTemplateFieldTarget(
                templateExercise: templateExercise,
                fieldDefinition: fieldDefinition,
                targetValueNumber: targetNumber,
                targetValueText: targetText
            )
            modelContext.insert(target)
        }
        templateExercise.template.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Create from Workout

    func createTemplate(from workout: Workout, user: User, name: String) throws -> WorkoutTemplate {
        let template = WorkoutTemplate(user: user, name: name)
        modelContext.insert(template)

        let sortedExercises = workout.workoutExercises.sorted { $0.sortOrder < $1.sortOrder }
        for workoutExercise in sortedExercises {
            guard let exercise = workoutExercise.exercise else { continue }

            let templateExercise = WorkoutTemplateExercise(
                template: template,
                exercise: exercise,
                sortOrder: workoutExercise.sortOrder,
                supersetGroup: workoutExercise.supersetGroup,
                targetSets: workoutExercise.sets.count
            )
            modelContext.insert(templateExercise)

            // Copy last set's values as field targets
            if let lastSet = workoutExercise.sets.max(by: { $0.setNumber < $1.setNumber }) {
                for value in lastSet.values {
                    let target = WorkoutTemplateFieldTarget(
                        templateExercise: templateExercise,
                        fieldDefinition: value.fieldDefinition,
                        targetValueNumber: value.valueNumber,
                        targetValueText: value.valueText
                    )
                    modelContext.insert(target)
                }
            }
        }

        try modelContext.save()
        return template
    }
}
