@testable import GHISA
import SwiftData
import Testing

struct ExerciseLibraryViewModelTests {
    @Test func loadExcludesArchived() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        let ex1 = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest"])
        _ = try service.createExercise(user: user, name: "Squat", muscleGroups: ["Quads"])
        try service.archiveExercise(ex1)

        let vm = ExerciseLibraryViewModel(service: service, user: user)
        vm.loadExercises()

        #expect(vm.exercises.count == 1)
        #expect(vm.exercises[0].name == "Squat")
    }

    @Test func loadIncludesArchived() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        let ex1 = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest"])
        _ = try service.createExercise(user: user, name: "Squat", muscleGroups: ["Quads"])
        try service.archiveExercise(ex1)

        let vm = ExerciseLibraryViewModel(service: service, user: user)
        vm.showArchived = true
        vm.loadExercises()

        #expect(vm.exercises.count == 2)
    }

    @Test func groupingByFirstMuscleGroup() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        _ = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest", "Triceps"])
        _ = try service.createExercise(user: user, name: "Squat", muscleGroups: ["Quads"])
        _ = try service.createExercise(user: user, name: "Fly", muscleGroups: ["Chest"])

        let vm = ExerciseLibraryViewModel(service: service, user: user)
        vm.loadExercises()

        let groups = vm.groupedExercises
        let groupNames = groups.map(\.0)
        #expect(groupNames.contains("Chest"))
        #expect(groupNames.contains("Quads"))

        let chestGroup = groups.first { $0.0 == "Chest" }
        #expect(chestGroup?.1.count == 2)
    }

    @Test func uncategorizedSectionForEmptyMuscleGroups() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        _ = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest"])
        _ = try service.createExercise(user: user, name: "Mystery Exercise")

        let vm = ExerciseLibraryViewModel(service: service, user: user)
        vm.loadExercises()

        let groups = vm.groupedExercises
        let groupNames = groups.map(\.0)
        #expect(groupNames.last == "Uncategorized")
    }

    @Test func searchFiltering() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)

        _ = try service.createExercise(user: user, name: "Bench Press", muscleGroups: ["Chest"])
        _ = try service.createExercise(user: user, name: "Squat", muscleGroups: ["Quads"])
        _ = try service.createExercise(user: user, name: "Incline Bench", muscleGroups: ["Chest"])

        let vm = ExerciseLibraryViewModel(service: service, user: user)
        vm.loadExercises()
        vm.searchText = "bench"

        let groups = vm.groupedExercises
        let allExercises = groups.flatMap(\.1)
        #expect(allExercises.count == 2)
        #expect(allExercises.allSatisfy { $0.name.localizedCaseInsensitiveContains("bench") })
    }
}
