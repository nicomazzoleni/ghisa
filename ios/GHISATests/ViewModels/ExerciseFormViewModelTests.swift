@testable import GHISA
import SwiftData
import Testing

struct ExerciseFormViewModelTests {
    @Test func validationRejectsEmptyName() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let vm = ExerciseFormViewModel(service: service, user: user)

        #expect(vm.isValid == false)

        vm.name = "   "
        #expect(vm.isValid == false)

        vm.name = "Bench Press"
        #expect(vm.isValid == true)
    }

    @Test func addAndRemoveMuscleGroups() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let vm = ExerciseFormViewModel(service: service, user: user)

        vm.muscleGroupText = "Chest"
        vm.addMuscleGroup()
        #expect(vm.muscleGroups == ["Chest"])
        #expect(vm.muscleGroupText.isEmpty)

        // Duplicate prevention
        vm.muscleGroupText = "Chest"
        vm.addMuscleGroup()
        #expect(vm.muscleGroups.count == 1)

        vm.muscleGroupText = "Triceps"
        vm.addMuscleGroup()
        #expect(vm.muscleGroups == ["Chest", "Triceps"])

        vm.removeMuscleGroup(at: 0)
        #expect(vm.muscleGroups == ["Triceps"])
    }

    @Test func addMuscleGroupIgnoresEmpty() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let vm = ExerciseFormViewModel(service: service, user: user)

        vm.muscleGroupText = ""
        vm.addMuscleGroup()
        #expect(vm.muscleGroups.isEmpty)

        vm.muscleGroupText = "   "
        vm.addMuscleGroup()
        #expect(vm.muscleGroups.isEmpty)
    }

    @Test func saveInCreateMode() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let vm = ExerciseFormViewModel(service: service, user: user)

        #expect(vm.isEditMode == false)

        vm.name = "Bench Press"
        vm.muscleGroupText = "Chest"
        vm.addMuscleGroup()

        let exercise = try vm.save()
        #expect(exercise.name == "Bench Press")
        #expect(exercise.muscleGroups == ["Chest"])
        #expect(exercise.fieldDefinitions.count == 2)
    }

    @Test func saveInEditMode() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(
            user: user,
            name: "Bench Press",
            muscleGroups: ["Chest"]
        )

        let vm = ExerciseFormViewModel(service: service, user: user, exercise: exercise)
        #expect(vm.isEditMode == true)
        #expect(vm.name == "Bench Press")
        #expect(vm.muscleGroups == ["Chest"])

        vm.name = "Incline Bench Press"
        vm.muscleGroupText = "Shoulders"
        vm.addMuscleGroup()

        let updated = try vm.save()
        #expect(updated.name == "Incline Bench Press")
        #expect(updated.muscleGroups == ["Chest", "Shoulders"])
        // Field count should not change on edit
        #expect(updated.fieldDefinitions.count == 2)
    }

    @Test func loadSuggestionsPopulatesLists() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        _ = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest"])
        _ = try service.createExercise(user: user, name: "Row", muscleGroups: ["Back"])

        let vm = ExerciseFormViewModel(service: service, user: user)
        vm.loadSuggestions()

        // User values (sorted from fetchDistinct) come first, then unseen defaults appended
        #expect(vm.muscleGroupSuggestions.prefix(2) == ["Back", "Chest"])
        #expect(vm.muscleGroupSuggestions.contains("Quads"))
        #expect(vm.muscleGroupSuggestions.contains("Glutes"))
    }

    @Test func editModePrePopulatesFields() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(
            user: user,
            name: "Squat",
            muscleGroups: ["Quads", "Glutes"]
        )

        let vm = ExerciseFormViewModel(service: service, user: user, exercise: exercise)
        #expect(vm.name == "Squat")
        #expect(vm.muscleGroups == ["Quads", "Glutes"])
        #expect(vm.isEditMode == true)
    }
}
