import Foundation
import SwiftData

@Observable
final class ExerciseFormViewModel {
    var name: String = ""
    var muscleGroupText: String = ""
    var muscleGroups: [String] = []

    var muscleGroupSuggestions: [String] = []

    var errorMessage: String?

    private let service: ExerciseService
    private let user: User
    private let existingExercise: Exercise?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEditMode: Bool {
        existingExercise != nil
    }

    init(service: ExerciseService, user: User, exercise: Exercise? = nil) {
        self.service = service
        self.user = user
        self.existingExercise = exercise

        if let exercise {
            self.name = exercise.name
            self.muscleGroups = exercise.muscleGroups
        }
    }

    private static let defaultMuscleGroups = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms",
        "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Full Body",
    ]

    func loadSuggestions() {
        let userMuscleGroups = (try? service.fetchDistinctMuscleGroups(for: user)) ?? []

        // Merge user values with defaults, preserving order (user first, then unseen defaults)
        var seenMG = Set(userMuscleGroups)
        var mergedMG = userMuscleGroups
        for mg in Self.defaultMuscleGroups where seenMG.insert(mg).inserted {
            mergedMG.append(mg)
        }
        muscleGroupSuggestions = mergedMG
    }

    func addMuscleGroup() {
        let trimmed = muscleGroupText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !muscleGroups.contains(trimmed) else { return }
        muscleGroups.append(trimmed)
        muscleGroupText = ""
    }

    func removeMuscleGroup(at index: Int) {
        guard muscleGroups.indices.contains(index) else { return }
        muscleGroups.remove(at: index)
    }

    func save() throws -> Exercise {
        if let exercise = existingExercise {
            try service.updateExercise(
                exercise,
                name: name,
                muscleGroups: muscleGroups
            )
            return exercise
        } else {
            return try service.createExercise(
                user: user,
                name: name,
                muscleGroups: muscleGroups
            )
        }
    }
}
