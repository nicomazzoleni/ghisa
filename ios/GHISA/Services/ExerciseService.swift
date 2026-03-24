import Foundation
import SwiftData

@Observable
final class ExerciseService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createExercise(
        user: User,
        name: String,
        muscleGroups: [String] = []
    ) throws -> Exercise {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.validation(message: "Exercise name cannot be empty.")
        }

        let exercise = Exercise(
            user: user,
            name: trimmed,
            muscleGroups: muscleGroups
        )
        modelContext.insert(exercise)
        seedDefaultFields(for: exercise)
        try modelContext.save()
        return exercise
    }

    // MARK: - Update

    func updateExercise(
        _ exercise: Exercise,
        name: String,
        muscleGroups: [String]
    ) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.validation(message: "Exercise name cannot be empty.")
        }

        exercise.name = trimmed
        exercise.muscleGroups = muscleGroups
        exercise.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Archive / Restore

    func archiveExercise(_ exercise: Exercise) throws {
        exercise.isArchived = true
        exercise.updatedAt = Date()
        try modelContext.save()
    }

    func restoreExercise(_ exercise: Exercise) throws {
        exercise.isArchived = false
        exercise.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Field Management

    func addCustomField(
        to exercise: Exercise,
        name: String,
        fieldType: String,
        unit: String? = nil,
        selectOptions: [String]? = nil
    ) throws -> ExerciseFieldDefinition {
        let nextSortOrder = exercise.fieldDefinitions.count
        let field = ExerciseFieldDefinition(
            exercise: exercise,
            name: name,
            fieldType: fieldType,
            unit: unit,
            selectOptions: selectOptions,
            sortOrder: nextSortOrder,
            isDefault: false
        )
        modelContext.insert(field)
        try modelContext.save()
        return field
    }

    func toggleFieldActive(_ field: ExerciseFieldDefinition) throws {
        field.isActive.toggle()
        try modelContext.save()
    }

    func reorderFields(_ exercise: Exercise, orderedIDs: [UUID]) throws {
        for (index, id) in orderedIDs.enumerated() {
            if let field = exercise.fieldDefinitions.first(where: { $0.id == id }) {
                field.sortOrder = index
            }
        }
        exercise.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Fetch

    func fetchExercises(for user: User, includeArchived: Bool = false) throws -> [Exercise] {
        let userId = user.id
        var descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.user.id == userId
            },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchLimit = nil
        var exercises = try modelContext.fetch(descriptor)

        if !includeArchived {
            exercises = exercises.filter { !$0.isArchived }
        }

        return exercises
    }

    func fetchDistinctMuscleGroups(for user: User) throws -> [String] {
        let exercises = try fetchExercises(for: user, includeArchived: false)
        var seen = Set<String>()
        var result: [String] = []
        for exercise in exercises {
            for group in exercise.muscleGroups where seen.insert(group).inserted {
                result.append(group)
            }
        }
        return result.sorted()
    }

    // MARK: - Default Fields

    private struct DefaultField {
        let name: String
        let fieldType: String
        let unit: String?
        let systemKey: String
        let sortOrder: Int
    }

    private static let defaultFields: [DefaultField] = [
        DefaultField(name: "Reps", fieldType: "number", unit: nil, systemKey: "reps", sortOrder: 0),
        DefaultField(name: "Weight", fieldType: "number", unit: "kg", systemKey: "weight", sortOrder: 1),
    ]

    private func seedDefaultFields(for exercise: Exercise) {
        for field in Self.defaultFields {
            let definition = ExerciseFieldDefinition(
                exercise: exercise,
                name: field.name,
                fieldType: field.fieldType,
                unit: field.unit,
                systemKey: field.systemKey,
                sortOrder: field.sortOrder,
                isDefault: true
            )
            modelContext.insert(definition)
        }
    }
}
