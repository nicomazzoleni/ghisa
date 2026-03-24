@testable import GHISA
import SwiftData
import Testing

struct FlagServiceTests {
    // MARK: - Create

    @Test func createFlagSucceeds() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        let flag = try service.createFlag(
            user: user,
            name: "Deload",
            color: "#30D158",
            icon: "arrow.down.circle.fill",
            scope: "workout"
        )

        #expect(flag.name == "Deload")
        #expect(flag.color == "#30D158")
        #expect(flag.icon == "arrow.down.circle.fill")
        #expect(flag.scope == "workout")
        #expect(flag.user.id == user.id)
    }

    @Test func createFlagTrimsWhitespace() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        let flag = try service.createFlag(
            user: user,
            name: "  PR Attempt  ",
            color: "#FF453A",
            scope: "exercise"
        )

        #expect(flag.name == "PR Attempt")
    }

    @Test func createFlagEmptyNameThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        #expect(throws: AppError.self) {
            try service.createFlag(user: user, name: "", color: "#0A84FF", scope: "workout")
        }
        #expect(throws: AppError.self) {
            try service.createFlag(user: user, name: "   ", color: "#0A84FF", scope: "workout")
        }
    }

    @Test func createFlagInvalidScopeThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        #expect(throws: AppError.self) {
            try service.createFlag(user: user, name: "Test", color: "#0A84FF", scope: "invalid")
        }
    }

    @Test func createDuplicateFlagInSameScopeThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        _ = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")

        #expect(throws: AppError.self) {
            try service.createFlag(user: user, name: "deload", color: "#FF453A", scope: "workout")
        }
    }

    @Test func createSameNameDifferentScopeSucceeds() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        let flag1 = try service.createFlag(user: user, name: "Warm-up", color: "#FFD60A", scope: "workout")
        let flag2 = try service.createFlag(user: user, name: "Warm-up", color: "#FFD60A", scope: "exercise")

        #expect(flag1.scope == "workout")
        #expect(flag2.scope == "exercise")
    }

    // MARK: - Update

    @Test func updateFlagChangesProperties() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        try service.updateFlag(flag, name: "Deload Week", color: "#FF9F0A", icon: "clock.fill")

        #expect(flag.name == "Deload Week")
        #expect(flag.color == "#FF9F0A")
        #expect(flag.icon == "clock.fill")
    }

    @Test func updateFlagEmptyNameThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")

        #expect(throws: AppError.self) {
            try service.updateFlag(flag, name: "", color: "#30D158", icon: nil)
        }
    }

    @Test func updateFlagDuplicateNameThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        _ = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        let flag2 = try service.createFlag(user: user, name: "Competition", color: "#FF453A", scope: "workout")

        #expect(throws: AppError.self) {
            try service.updateFlag(flag2, name: "Deload", color: "#FF453A", icon: nil)
        }
    }

    // MARK: - Delete

    @Test func deleteFlagRemovesFromUser() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        #expect(service.fetchFlags(for: user).count == 1)

        try service.deleteFlag(flag)
        #expect(service.fetchFlags(for: user).isEmpty)
    }

    // MARK: - Fetch

    @Test func fetchFlagsFiltersByScope() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        _ = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        _ = try service.createFlag(user: user, name: "PR Attempt", color: "#FF453A", scope: "exercise")
        _ = try service.createFlag(user: user, name: "Drop Set", color: "#BF5AF2", scope: "set")

        #expect(service.fetchFlags(for: user).count == 3)
        #expect(service.fetchFlags(for: user, scope: "workout").count == 1)
        #expect(service.fetchFlags(for: user, scope: "exercise").count == 1)
        #expect(service.fetchFlags(for: user, scope: "set").count == 1)
    }

    @Test func fetchFlagsSortedByName() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)

        _ = try service.createFlag(user: user, name: "Zzz", color: "#30D158", scope: "workout")
        _ = try service.createFlag(user: user, name: "Alpha", color: "#FF453A", scope: "workout")
        _ = try service.createFlag(user: user, name: "Mid", color: "#BF5AF2", scope: "workout")

        let flags = service.fetchFlags(for: user, scope: "workout")
        #expect(flags.map(\.name) == ["Alpha", "Mid", "Zzz"])
    }

    // MARK: - Assign

    @Test func assignWorkoutFlagSucceeds() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)
        let workoutService = WorkoutService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        let workout = try workoutService.startWorkout(user: user)

        let assignment = try service.assignFlag(flag, to: workout)
        #expect(assignment.workout?.id == workout.id)
        #expect(workout.flagAssignments.count == 1)
    }

    @Test func assignExerciseFlagSucceeds() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)
        let workoutService = WorkoutService(modelContext: context)
        let exerciseService = ExerciseService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "PR Attempt", color: "#FF453A", scope: "exercise")
        let workout = try workoutService.startWorkout(user: user)
        let exercise = try exerciseService.createExercise(user: user, name: "Bench Press")
        let workoutExercise = try workoutService.addExercise(to: workout, exercise: exercise)

        let assignment = try service.assignFlag(flag, to: workoutExercise)
        #expect(assignment.workoutExercise?.id == workoutExercise.id)
        #expect(workoutExercise.flagAssignments.count == 1)
    }

    @Test func assignSetFlagSucceeds() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)
        let workoutService = WorkoutService(modelContext: context)
        let exerciseService = ExerciseService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Drop Set", color: "#BF5AF2", scope: "set")
        let workout = try workoutService.startWorkout(user: user)
        let exercise = try exerciseService.createExercise(user: user, name: "Bench Press")
        let workoutExercise = try workoutService.addExercise(to: workout, exercise: exercise)
        let set = try #require(workoutExercise.sets.first)

        let assignment = try service.assignFlag(flag, to: set)
        #expect(assignment.workoutSet?.id == set.id)
        #expect(set.flagAssignments.count == 1)
    }

    @Test func assignWrongScopeThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)
        let workoutService = WorkoutService(modelContext: context)

        let exerciseFlag = try service.createFlag(user: user, name: "PR Attempt", color: "#FF453A", scope: "exercise")
        let workout = try workoutService.startWorkout(user: user)

        #expect(throws: AppError.self) {
            try service.assignFlag(exerciseFlag, to: workout)
        }
    }

    @Test func assignDuplicateFlagThrows() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)
        let workoutService = WorkoutService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        let workout = try workoutService.startWorkout(user: user)

        _ = try service.assignFlag(flag, to: workout)
        #expect(throws: AppError.self) {
            try service.assignFlag(flag, to: workout)
        }
    }

    // MARK: - Remove Assignment

    @Test func removeAssignmentSucceeds() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = FlagService(modelContext: context)
        let workoutService = WorkoutService(modelContext: context)

        let flag = try service.createFlag(user: user, name: "Deload", color: "#30D158", scope: "workout")
        let workout = try workoutService.startWorkout(user: user)

        let assignment = try service.assignFlag(flag, to: workout)
        #expect(workout.flagAssignments.count == 1)

        try service.removeAssignment(assignment)
        #expect(workout.flagAssignments.isEmpty)
    }
}
