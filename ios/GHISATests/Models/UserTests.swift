@testable import GHISA
import Testing

struct UserTests {
    @Test func userDefaultValues() {
        let user = User()
        #expect(user.unitSystem == "metric")
        #expect(user.name == nil)
        #expect(user.age == nil)
        #expect(user.gender == nil)
        #expect(user.heightCm == nil)
        #expect(user.weightKg == nil)
        #expect(user.exercises.isEmpty)
        #expect(user.workouts.isEmpty)
    }

    @Test func userWithName() {
        let user = User(name: "Test User")
        #expect(user.name == "Test User")
        #expect(user.unitSystem == "metric")
    }

    @Test func userWithImperialUnits() {
        let user = User(unitSystem: "imperial")
        #expect(user.unitSystem == "imperial")
    }
}
