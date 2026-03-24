@testable import GHISA
import SwiftData
import Testing

struct ExerciseDetailViewModelTests {
    @Test func archiveAndRestore() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Squat")

        let vm = ExerciseDetailViewModel(service: service, exercise: exercise)

        vm.archiveExercise()
        #expect(exercise.isArchived == true)

        vm.restoreExercise()
        #expect(exercise.isArchived == false)
    }

    @Test func toggleFieldActive() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Squat")

        let vm = ExerciseDetailViewModel(service: service, exercise: exercise)
        let field = try #require(vm.sortedFields.first)

        #expect(field.isActive == true)
        vm.toggleFieldActive(field)
        #expect(field.isActive == false)
    }

    @Test func addCustomField() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Squat")

        let vm = ExerciseDetailViewModel(service: service, exercise: exercise)
        let initialCount = exercise.fieldDefinitions.count

        vm.addCustomField(name: "RPE", fieldType: "number", unit: nil, selectOptions: nil)
        #expect(exercise.fieldDefinitions.count == initialCount + 1)

        let rpe = exercise.fieldDefinitions.first { $0.name == "RPE" }
        #expect(rpe != nil)
        #expect(rpe?.isDefault == false)
    }

    @Test func sortedFieldsOrdering() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = ExerciseService(modelContext: context)
        let exercise = try service.createExercise(user: user, name: "Squat")

        let vm = ExerciseDetailViewModel(service: service, exercise: exercise)
        vm.addCustomField(name: "RPE", fieldType: "number", unit: nil, selectOptions: nil)

        let sorted = vm.sortedFields
        for i in 0 ..< (sorted.count - 1) {
            #expect(sorted[i].sortOrder <= sorted[i + 1].sortOrder)
        }
    }
}
