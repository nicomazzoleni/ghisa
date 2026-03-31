@testable import GHISA
import Testing

struct CorrelationVariableTests {
    @Test func registryIncludesAllBuiltInLifestyleVariables() {
        let variables = CorrelationVariable.allVariables(
            exercises: [],
            muscleGroups: [],
            nutrientDefinitions: [],
            customDailyFields: []
        )

        let lifestyleIds = Set(variables.filter { $0.category == .lifestyle }.map(\.id))
        #expect(lifestyleIds.contains("sleep_hours"))
        #expect(lifestyleIds.contains("hrv"))
        #expect(lifestyleIds.contains("steps"))
        #expect(lifestyleIds.contains("resting_hr"))
        #expect(lifestyleIds.contains("active_energy_kcal"))
    }

    @Test func registryIncludesNutritionVariables() {
        let variables = CorrelationVariable.allVariables(
            exercises: [],
            muscleGroups: [],
            nutrientDefinitions: [],
            customDailyFields: []
        )

        let nutritionIds = Set(variables.filter { $0.category == .nutrition }.map(\.id))
        #expect(nutritionIds.contains("daily_calories"))
        #expect(nutritionIds.contains("daily_protein_g"))
        #expect(nutritionIds.contains("daily_carbs_g"))
        #expect(nutritionIds.contains("daily_fat_g"))
        #expect(nutritionIds.contains("meal_timing_hours"))
    }

    @Test func registryGeneratesPerExerciseTargets() {
        let exercises = [
            ExerciseInfo(id: .init(), name: "Squat", muscleGroups: ["Quadriceps"]),
            ExerciseInfo(id: .init(), name: "Bench Press", muscleGroups: ["Chest"]),
        ]

        let variables = CorrelationVariable.allVariables(
            exercises: exercises,
            muscleGroups: ["Quadriceps", "Chest"],
            nutrientDefinitions: [],
            customDailyFields: []
        )

        let e1rmVars = variables.filter { $0.id.hasPrefix("e1rm_") }
        #expect(e1rmVars.count == 2)
        #expect(e1rmVars.filter { !$0.isTarget }.isEmpty)

        let volumeVars = variables.filter { $0.id.hasPrefix("volume_") }
        #expect(volumeVars.count == 2) // quadriceps + chest
    }

    @Test func registryIncludesDerivedVariables() {
        let variables = CorrelationVariable.allVariables(
            exercises: [],
            muscleGroups: [],
            nutrientDefinitions: [],
            customDailyFields: []
        )

        let derivedIds = Set(variables.filter { $0.category == .derived }.map(\.id))
        #expect(derivedIds.contains("training_day"))
        #expect(derivedIds.contains("time_of_day_bucket"))
    }

    @Test func registryHandlesCustomFields() {
        let customFields = [
            CustomFieldInfo(id: .init(), name: "Stress", fieldType: "number"),
            CustomFieldInfo(id: .init(), name: "Creatine", fieldType: "toggle"),
        ]

        let variables = CorrelationVariable.allVariables(
            exercises: [],
            muscleGroups: [],
            nutrientDefinitions: [],
            customDailyFields: customFields
        )

        let customVars = variables.filter { $0.id.hasPrefix("custom_") }
        #expect(customVars.count == 2)

        let stressVar = customVars.first { $0.displayName == "Stress" }
        #expect(stressVar?.variableType == .continuous)

        let creatineVar = customVars.first { $0.displayName == "Creatine" }
        #expect(creatineVar?.variableType == .binary)
    }

    @Test func registryExcludesCoreNutrientsFromPerNutrient() {
        let nutrients = [
            NutrientDefinitionInfo(id: .init(), name: "Calories", unit: "kcal", apiKey: "energy-kcal"),
            NutrientDefinitionInfo(id: .init(), name: "Vitamin D", unit: "mcg", apiKey: "vitamin-d"),
        ]

        let variables = CorrelationVariable.allVariables(
            exercises: [],
            muscleGroups: [],
            nutrientDefinitions: nutrients,
            customDailyFields: []
        )

        // Calories should NOT have a separate nutrient_ variable (already has daily_calories)
        let nutrientVars = variables.filter { $0.id.hasPrefix("nutrient_") }
        #expect(nutrientVars.count == 1)
        #expect(nutrientVars[0].displayName == "Daily Vitamin D")
    }
}
