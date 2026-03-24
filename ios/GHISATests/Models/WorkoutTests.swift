@testable import GHISA
import Testing

struct WorkoutTests {
    @Test func workoutDefaultValues() {
        let user = User()
        let workout = Workout(user: user)
        #expect(workout.status == "in_progress")
        #expect(workout.notes == nil)
        #expect(workout.location == nil)
        #expect(workout.durationMinutes == nil)
        #expect(workout.workoutExercises.isEmpty)
    }
}
