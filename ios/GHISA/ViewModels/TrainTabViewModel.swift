import Foundation
import SwiftData

@Observable
final class TrainTabViewModel {
    var inProgressWorkout: Workout?
    var completedWorkouts: [Workout] = []
    var templates: [WorkoutTemplate] = []
    var errorMessage: String?

    private let workoutService: WorkoutService
    private let templateService: WorkoutTemplateService
    private let user: User

    init(workoutService: WorkoutService, templateService: WorkoutTemplateService, user: User) {
        self.workoutService = workoutService
        self.templateService = templateService
        self.user = user
    }

    func loadState() {
        do {
            inProgressWorkout = try workoutService.fetchInProgressWorkout(for: user)
            completedWorkouts = try workoutService.fetchCompletedWorkouts(for: user, limit: 5)
            templates = try templateService.fetchTemplates(for: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startNewWorkout() throws -> Workout {
        let workout = try workoutService.startWorkout(user: user)
        inProgressWorkout = workout
        return workout
    }

    func startFromTemplate(_ template: WorkoutTemplate) throws -> Workout {
        let workout = try workoutService.startWorkoutFromTemplate(user: user, template: template)
        inProgressWorkout = workout
        return workout
    }

    func copyPreviousWorkout(_ source: Workout) throws -> Workout {
        let workout = try workoutService.copyWorkout(user: user, source: source)
        inProgressWorkout = workout
        return workout
    }
}
