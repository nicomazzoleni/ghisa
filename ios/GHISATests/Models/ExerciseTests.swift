@testable import GHISA
import Testing

struct ExerciseTests {
    @Test func exerciseDefaultValues() {
        let user = User()
        let exercise = Exercise(user: user, name: "Bench Press")
        #expect(exercise.name == "Bench Press")
        #expect(exercise.muscleGroups.isEmpty)
        #expect(exercise.isArchived == false)
        #expect(exercise.fieldDefinitions.isEmpty)
    }

    @Test func exerciseWithMuscleGroups() {
        let user = User()
        let exercise = Exercise(
            user: user,
            name: "Squat",
            muscleGroups: ["Quadriceps", "Glutes"]
        )
        #expect(exercise.muscleGroups.count == 2)
    }
}
