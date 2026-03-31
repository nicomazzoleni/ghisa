import Foundation

// MARK: - Variable Type Classification

enum VariableType: String, Codable {
    case continuous
    case ordinal
    case binary
    case categorical
}

// MARK: - Variable Category

enum VariableCategory: String, Codable {
    case training
    case nutrition
    case lifestyle
    case derived
}

// MARK: - Correlation Variable

struct CorrelationVariable: Identifiable, Hashable {
    let id: String
    let displayName: String
    let variableType: VariableType
    let category: VariableCategory
    let isTarget: Bool
    let exerciseId: UUID?
    let muscleGroup: String?
    let nutrientDefinitionId: UUID?
    let customFieldId: UUID?

    init(
        id: String,
        displayName: String,
        variableType: VariableType,
        category: VariableCategory,
        isTarget: Bool = false,
        exerciseId: UUID? = nil,
        muscleGroup: String? = nil,
        nutrientDefinitionId: UUID? = nil,
        customFieldId: UUID? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.variableType = variableType
        self.category = category
        self.isTarget = isTarget
        self.exerciseId = exerciseId
        self.muscleGroup = muscleGroup
        self.nutrientDefinitionId = nutrientDefinitionId
        self.customFieldId = customFieldId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CorrelationVariable, rhs: CorrelationVariable) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Variable Registry

extension CorrelationVariable {
    /// Build the full list of variables from the user's exercises, nutrient definitions, and custom fields.
    static func allVariables( // swiftlint:disable:this function_body_length
        exercises: [ExerciseInfo],
        muscleGroups: [String],
        nutrientDefinitions: [NutrientDefinitionInfo],
        customDailyFields: [CustomFieldInfo]
    ) -> [CorrelationVariable] {
        var variables: [CorrelationVariable] = []

        // --- Training targets ---
        variables.append(CorrelationVariable(
            id: "session_volume",
            displayName: "Session Volume",
            variableType: .continuous,
            category: .training,
            isTarget: true
        ))

        for group in muscleGroups {
            variables.append(CorrelationVariable(
                id: "volume_\(group.lowercased().replacingOccurrences(of: " ", with: "_"))",
                displayName: "\(group) Volume",
                variableType: .continuous,
                category: .training,
                isTarget: true,
                muscleGroup: group
            ))
        }

        for exercise in exercises {
            variables.append(CorrelationVariable(
                id: "e1rm_\(exercise.id.uuidString)",
                displayName: "\(exercise.name) e1RM",
                variableType: .continuous,
                category: .training,
                isTarget: true,
                exerciseId: exercise.id
            ))
        }

        variables.append(CorrelationVariable(
            id: "sets_to_failure",
            displayName: "Sets to Failure",
            variableType: .continuous,
            category: .training,
            isTarget: true
        ))

        variables.append(CorrelationVariable(
            id: "avg_rpe",
            displayName: "Average RPE",
            variableType: .ordinal,
            category: .training,
            isTarget: true
        ))

        variables.append(CorrelationVariable(
            id: "pr_frequency",
            displayName: "PR Frequency",
            variableType: .continuous,
            category: .training,
            isTarget: true
        ))

        // --- Nutrition factors ---
        variables.append(CorrelationVariable(
            id: "daily_calories",
            displayName: "Daily Calories",
            variableType: .continuous,
            category: .nutrition
        ))

        variables.append(CorrelationVariable(
            id: "daily_protein_g",
            displayName: "Daily Protein (g)",
            variableType: .continuous,
            category: .nutrition
        ))

        variables.append(CorrelationVariable(
            id: "daily_carbs_g",
            displayName: "Daily Carbs (g)",
            variableType: .continuous,
            category: .nutrition
        ))

        variables.append(CorrelationVariable(
            id: "daily_fat_g",
            displayName: "Daily Fat (g)",
            variableType: .continuous,
            category: .nutrition
        ))

        variables.append(CorrelationVariable(
            id: "meal_timing_hours",
            displayName: "Pre-Workout Meal Timing (h)",
            variableType: .continuous,
            category: .nutrition
        ))

        variables.append(CorrelationVariable(
            id: "caloric_surplus_deficit",
            displayName: "Caloric Surplus/Deficit",
            variableType: .continuous,
            category: .nutrition
        ))

        // Per-nutrient variables (beyond the core macros)
        for nutrient in nutrientDefinitions where !coreNutrientApiKeys.contains(nutrient.apiKey ?? "") {
            variables.append(CorrelationVariable(
                id: "nutrient_\(nutrient.id.uuidString)",
                displayName: "Daily \(nutrient.name)",
                variableType: .continuous,
                category: .nutrition,
                nutrientDefinitionId: nutrient.id
            ))
        }

        // --- Lifestyle factors ---
        variables.append(contentsOf: builtInLifestyleVariables)

        // Custom daily log fields
        for field in customDailyFields {
            let varType: VariableType = switch field.fieldType {
                case "number": .continuous
                case "toggle": .binary
                default: .categorical
            }
            variables.append(CorrelationVariable(
                id: "custom_\(field.id.uuidString)",
                displayName: field.name,
                variableType: varType,
                category: .lifestyle,
                customFieldId: field.id
            ))
        }

        // --- Derived variables ---
        variables.append(CorrelationVariable(
            id: "training_day",
            displayName: "Training Day",
            variableType: .binary,
            category: .derived
        ))

        variables.append(CorrelationVariable(
            id: "time_of_day_bucket",
            displayName: "Time of Day",
            variableType: .categorical,
            category: .derived
        ))

        return variables
    }

    // MARK: - Built-in Lifestyle Variables

    static let builtInLifestyleVariables: [CorrelationVariable] = [
        CorrelationVariable(
            id: "sleep_hours",
            displayName: "Sleep Duration (h)",
            variableType: .continuous,
            category: .lifestyle
        ),
        CorrelationVariable(
            id: "sleep_deep_minutes",
            displayName: "Deep Sleep (min)",
            variableType: .continuous,
            category: .lifestyle
        ),
        CorrelationVariable(
            id: "sleep_core_minutes",
            displayName: "Core Sleep (min)",
            variableType: .continuous,
            category: .lifestyle
        ),
        CorrelationVariable(
            id: "sleep_rem_minutes",
            displayName: "REM Sleep (min)",
            variableType: .continuous,
            category: .lifestyle
        ),
        CorrelationVariable(id: "steps", displayName: "Steps", variableType: .continuous, category: .lifestyle),
        CorrelationVariable(
            id: "resting_hr",
            displayName: "Resting Heart Rate",
            variableType: .continuous,
            category: .lifestyle
        ),
        CorrelationVariable(id: "hrv", displayName: "HRV", variableType: .continuous, category: .lifestyle),
        CorrelationVariable(
            id: "active_energy_kcal",
            displayName: "Active Energy (kcal)",
            variableType: .continuous,
            category: .lifestyle
        ),
        CorrelationVariable(
            id: "walking_distance_km",
            displayName: "Walking Distance (km)",
            variableType: .continuous,
            category: .lifestyle
        ),
    ]

    // MARK: - Helpers

    /// Core macro nutrient API keys that already have dedicated variables (daily_calories, daily_protein_g, etc.)
    private static let coreNutrientApiKeys: Set<String> = [
        "energy-kcal", "proteins", "carbohydrates", "fat",
    ]
}

// MARK: - Lightweight Info Structs (avoid passing SwiftData models into Sendable contexts)

struct ExerciseInfo {
    let id: UUID
    let name: String
    let muscleGroups: [String]
}

struct NutrientDefinitionInfo {
    let id: UUID
    let name: String
    let unit: String
    let apiKey: String?
}

struct CustomFieldInfo {
    let id: UUID
    let name: String
    let fieldType: String
}
