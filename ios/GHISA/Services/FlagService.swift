import Foundation
import SwiftData

@Observable
final class FlagService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createFlag(
        user: User,
        name: String,
        color: String,
        icon: String? = nil,
        scope: String
    ) throws -> Flag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.validation(message: "Flag name cannot be empty.")
        }

        guard ["workout", "exercise", "set"].contains(scope) else {
            throw AppError.validation(message: "Invalid flag scope.")
        }

        let existing = user.flags.first { $0.name.lowercased() == trimmed.lowercased() && $0.scope == scope }
        if existing != nil {
            throw AppError.validation(message: "A \(scope) flag named \"\(trimmed)\" already exists.")
        }

        let flag = Flag(user: user, name: trimmed, color: color, icon: icon, scope: scope)
        modelContext.insert(flag)
        try modelContext.save()
        return flag
    }

    // MARK: - Update

    func updateFlag(
        _ flag: Flag,
        name: String,
        color: String,
        icon: String?
    ) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.validation(message: "Flag name cannot be empty.")
        }

        let duplicate = flag.user.flags.first {
            $0.id != flag.id && $0.name.lowercased() == trimmed.lowercased() && $0.scope == flag.scope
        }
        if duplicate != nil {
            throw AppError.validation(message: "A \(flag.scope) flag named \"\(trimmed)\" already exists.")
        }

        flag.name = trimmed
        flag.color = color
        flag.icon = icon
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteFlag(_ flag: Flag) throws {
        modelContext.delete(flag)
        try modelContext.save()
    }

    // MARK: - Fetch

    func fetchFlags(for user: User, scope: String? = nil) -> [Flag] {
        var flags = user.flags
        if let scope {
            flags = flags.filter { $0.scope == scope }
        }
        return flags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Assign

    func assignFlag(_ flag: Flag, to workout: Workout) throws -> FlagAssignment {
        guard flag.scope == "workout" else {
            throw AppError.validation(message: "This flag can only be assigned to a \(flag.scope).")
        }

        if workout.flagAssignments.contains(where: { $0.flag.id == flag.id }) {
            throw AppError.validation(message: "Flag \"\(flag.name)\" is already assigned.")
        }

        let assignment = FlagAssignment(flag: flag, workout: workout)
        modelContext.insert(assignment)
        try modelContext.save()
        return assignment
    }

    func assignFlag(_ flag: Flag, to workoutExercise: WorkoutExercise) throws -> FlagAssignment {
        guard flag.scope == "exercise" else {
            throw AppError.validation(message: "This flag can only be assigned to a \(flag.scope).")
        }

        if workoutExercise.flagAssignments.contains(where: { $0.flag.id == flag.id }) {
            throw AppError.validation(message: "Flag \"\(flag.name)\" is already assigned.")
        }

        let assignment = FlagAssignment(flag: flag, workoutExercise: workoutExercise)
        modelContext.insert(assignment)
        try modelContext.save()
        return assignment
    }

    func assignFlag(_ flag: Flag, to workoutSet: WorkoutSet) throws -> FlagAssignment {
        guard flag.scope == "set" else {
            throw AppError.validation(message: "This flag can only be assigned to a \(flag.scope).")
        }

        if workoutSet.flagAssignments.contains(where: { $0.flag.id == flag.id }) {
            throw AppError.validation(message: "Flag \"\(flag.name)\" is already assigned.")
        }

        let assignment = FlagAssignment(flag: flag, workoutSet: workoutSet)
        modelContext.insert(assignment)
        try modelContext.save()
        return assignment
    }

    // MARK: - Remove Assignment

    func removeAssignment(_ assignment: FlagAssignment) throws {
        modelContext.delete(assignment)
        try modelContext.save()
    }
}
