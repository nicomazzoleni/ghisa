import Foundation

enum TrainingSeedConfig {
    static let seededExerciseNames = [
        "Squat", "Bench Press", "Barbell Row",
        "Deadlift", "Overhead Press", "Pull-ups",
    ]

    struct ExerciseConfig {
        let name: String
        let muscleGroups: [String]
        let hasWeight: Bool
        let defaultSets: Int
        let defaultReps: Int
        let startWeight: Float
        let targetWeight: Float
        let startReps: Int
        let targetReps: Int
        let day: String // "A" or "B"
    }

    static let exerciseConfigs: [ExerciseConfig] = [
        // Day A
        ExerciseConfig(
            name: "Squat",
            muscleGroups: ["Quadriceps", "Glutes"],
            hasWeight: true,
            defaultSets: 4,
            defaultReps: 5,
            startWeight: 120,
            targetWeight: 160,
            startReps: 5,
            targetReps: 5,
            day: "A"
        ),
        ExerciseConfig(
            name: "Bench Press",
            muscleGroups: ["Chest", "Triceps"],
            hasWeight: true,
            defaultSets: 4,
            defaultReps: 5,
            startWeight: 70,
            targetWeight: 95,
            startReps: 5,
            targetReps: 5,
            day: "A"
        ),
        ExerciseConfig(
            name: "Barbell Row",
            muscleGroups: ["Back", "Biceps"],
            hasWeight: true,
            defaultSets: 3,
            defaultReps: 8,
            startWeight: 85,
            targetWeight: 125,
            startReps: 8,
            targetReps: 8,
            day: "A"
        ),
        // Day B
        ExerciseConfig(
            name: "Deadlift",
            muscleGroups: ["Back", "Hamstrings", "Glutes"],
            hasWeight: true,
            defaultSets: 3,
            defaultReps: 5,
            startWeight: 140,
            targetWeight: 190,
            startReps: 5,
            targetReps: 5,
            day: "B"
        ),
        ExerciseConfig(
            name: "Overhead Press",
            muscleGroups: ["Shoulders", "Triceps"],
            hasWeight: true,
            defaultSets: 4,
            defaultReps: 5,
            startWeight: 50,
            targetWeight: 72,
            startReps: 5,
            targetReps: 5,
            day: "B"
        ),
        ExerciseConfig(
            name: "Pull-ups",
            muscleGroups: ["Back", "Biceps"],
            hasWeight: false,
            defaultSets: 3,
            defaultReps: 0,
            startWeight: 0,
            targetWeight: 0,
            startReps: 7,
            targetReps: 11,
            day: "B"
        ),
    ]
}
