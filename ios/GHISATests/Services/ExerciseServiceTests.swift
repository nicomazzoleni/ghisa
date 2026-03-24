@testable import GHISA
import SwiftData
import Testing

struct ExerciseServiceTests {
    @Test func createExerciseSeedsDefaultFields() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        let exercise = try service.createExercise(
            user: user,
            name: "Bench Press",
            muscleGroups: ["Chest", "Triceps"]
        )

        #expect(exercise.name == "Bench Press")
        #expect(exercise.fieldDefinitions.count == 2)

        let systemKeys = exercise.fieldDefinitions.compactMap(\.systemKey).sorted()
        #expect(systemKeys == ["reps", "weight"])

        let allDefault = exercise.fieldDefinitions.allSatisfy(\.isDefault)
        #expect(allDefault == true)
    }

    @Test func addCustomFieldToExercise() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Cable Fly")

        let customField = try service.addCustomField(
            to: exercise,
            name: "Grip Width",
            fieldType: "select",
            selectOptions: ["wide", "normal", "close"]
        )

        #expect(customField.isDefault == false)
        #expect(customField.systemKey == nil)
        #expect(customField.selectOptions?.count == 3)
    }

    @Test func createExerciseWithEmptyNameThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        #expect(throws: AppError.self) {
            try service.createExercise(user: user, name: "")
        }
        #expect(throws: AppError.self) {
            try service.createExercise(user: user, name: "   ")
        }
    }

    @Test func updateExerciseChangesFields() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(
            user: user,
            name: "Bench Press",
            muscleGroups: ["Chest"]
        )

        try service.updateExercise(
            exercise,
            name: "Incline Bench Press",
            muscleGroups: ["Chest", "Shoulders"]
        )

        #expect(exercise.name == "Incline Bench Press")
        #expect(exercise.muscleGroups == ["Chest", "Shoulders"])
    }

    @Test func updateExerciseEmptyNameThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Squat")

        #expect(throws: AppError.self) {
            try service.updateExercise(exercise, name: "", muscleGroups: [])
        }
    }

    @Test func archiveExerciseSetsFlag() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Deadlift")

        #expect(exercise.isArchived == false)
        try service.archiveExercise(exercise)
        #expect(exercise.isArchived == true)
    }

    @Test func restoreExerciseClearsFlag() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Deadlift")

        try service.archiveExercise(exercise)
        #expect(exercise.isArchived == true)

        try service.restoreExercise(exercise)
        #expect(exercise.isArchived == false)
    }

    @Test func toggleFieldActiveFlips() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Squat")

        let field = try #require(exercise.fieldDefinitions.first)
        #expect(field.isActive == true)

        try service.toggleFieldActive(field)
        #expect(field.isActive == false)

        try service.toggleFieldActive(field)
        #expect(field.isActive == true)
    }

    @Test func fetchExercisesExcludesArchived() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        let ex1 = try service.createExercise(user: user, name: "Bench Press")
        _ = try service.createExercise(user: user, name: "Squat")
        try service.archiveExercise(ex1)

        let active = try service.fetchExercises(for: user, includeArchived: false)
        #expect(active.count == 1)
        #expect(active[0].name == "Squat")
    }

    @Test func fetchExercisesIncludesArchived() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        let ex1 = try service.createExercise(user: user, name: "Bench Press")
        _ = try service.createExercise(user: user, name: "Squat")
        try service.archiveExercise(ex1)

        let all = try service.fetchExercises(for: user, includeArchived: true)
        #expect(all.count == 2)
    }

    @Test func fetchDistinctMuscleGroups() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        _ = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest", "Triceps"])
        _ = try service.createExercise(user: user, name: "Squat", muscleGroups: ["Quads", "Glutes"])
        _ = try service.createExercise(user: user, name: "Dips", muscleGroups: ["Chest", "Triceps"])

        let groups = try service.fetchDistinctMuscleGroups(for: user)
        #expect(groups == ["Chest", "Glutes", "Quads", "Triceps"])
    }
}
