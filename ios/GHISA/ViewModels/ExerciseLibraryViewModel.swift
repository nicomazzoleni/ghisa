import Foundation
import SwiftData

@Observable
final class ExerciseLibraryViewModel {
    var exercises: [Exercise] = []
    var searchText: String = ""
    var showArchived: Bool = false

    private let service: ExerciseService
    private let user: User

    init(service: ExerciseService, user: User) {
        self.service = service
        self.user = user
    }

    var groupedExercises: [(String, [Exercise])] {
        let source = exercises.filter { exercise in
            guard !searchText.isEmpty else { return true }
            return exercise.name.localizedCaseInsensitiveContains(searchText)
        }

        var groups: [String: [Exercise]] = [:]
        for exercise in source {
            let key = exercise.muscleGroups.first ?? "Uncategorized"
            groups[key, default: []].append(exercise)
        }

        return groups.sorted { lhs, rhs in
            if lhs.key == "Uncategorized" { return false }
            if rhs.key == "Uncategorized" { return true }
            return lhs.key < rhs.key
        }
    }

    func loadExercises() {
        exercises = (try? service.fetchExercises(for: user, includeArchived: showArchived)) ?? []
    }
}
