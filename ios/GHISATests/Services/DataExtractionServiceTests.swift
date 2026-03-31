import Foundation
@testable import GHISA
import SwiftData
import Testing

struct DataExtractionServiceTests {
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: User.self, Exercise.self, ExerciseFieldDefinition.self,
            WorkoutSetValue.self, WorkoutExercise.self, WorkoutSet.self,
            WorkoutTemplateExercise.self, WorkoutTemplateFieldTarget.self,
            Workout.self, FlagAssignment.self, Flag.self,
            WorkoutTemplate.self, NutrientDefinition.self,
            FoodItem.self, FoodItemNutrient.self, Recipe.self,
            RecipeIngredient.self, MealCategory.self, MealEntry.self,
            MealTemplate.self, MealTemplateItem.self, NutritionTarget.self,
            DailyLog.self, DailyLogFieldDefinition.self, DailyLogValue.self,
            CorrelationResult.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - Training Variable Extraction

    @Test func extractSessionVolume() throws {
        let context = try makeContext()
        let (user, _) = try createTestWorkout(context: context, weight: 100, reps: 5, sets: 3)

        let service = DataExtractionService(modelContext: context)
        let variable = CorrelationVariable(
            id: "session_volume",
            displayName: "Session Volume",
            variableType: .continuous,
            category: .training,
            isTarget: true
        )

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = try #require(calendar.date(byAdding: .day, value: -7, to: today))
        let series = try service.extractTimeSeries(variable: variable, userId: user.id, dateRange: weekAgo ... today)

        try #require(series.count == 1)
        // 3 sets × 100kg × 5 reps = 1500
        #expect(abs(series[0].value - 1500.0) < 0.01)
    }

    @Test func extractE1RM() throws {
        let context = try makeContext()
        let (user, exercise) = try createTestWorkout(context: context, weight: 100, reps: 5, sets: 1)

        let service = DataExtractionService(modelContext: context)
        let variable = CorrelationVariable(
            id: "e1rm_\(exercise.id.uuidString)",
            displayName: "Test e1RM",
            variableType: .continuous,
            category: .training,
            isTarget: true,
            exerciseId: exercise.id
        )

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = try #require(calendar.date(byAdding: .day, value: -7, to: today))
        let series = try service.extractTimeSeries(variable: variable, userId: user.id, dateRange: weekAgo ... today)

        try #require(series.count == 1)
        // Epley: 100 × (1 + 5/30) = 116.67
        #expect(abs(series[0].value - 116.67) < 0.1)
    }

    // MARK: - Lifestyle Variable Extraction

    @Test func extractSleepHours() throws {
        let context = try makeContext()
        let user = User()
        context.insert(user)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let log = DailyLog(user: user, date: today)
        log.sleepHours = 7.5
        context.insert(log)
        try context.save()

        let service = DataExtractionService(modelContext: context)
        let variable = CorrelationVariable(
            id: "sleep_hours",
            displayName: "Sleep Duration",
            variableType: .continuous,
            category: .lifestyle
        )

        let weekAgo = try #require(calendar.date(byAdding: .day, value: -7, to: today))
        let series = try service.extractTimeSeries(variable: variable, userId: user.id, dateRange: weekAgo ... today)

        try #require(series.count == 1)
        #expect(abs(series[0].value - 7.5) < 0.01)
    }

    @Test func extractSleepHoursSkipsNil() throws {
        let context = try makeContext()
        let user = User()
        context.insert(user)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Log without sleep data
        let log = DailyLog(user: user, date: today)
        context.insert(log)
        try context.save()

        let service = DataExtractionService(modelContext: context)
        let variable = CorrelationVariable(
            id: "sleep_hours",
            displayName: "Sleep Duration",
            variableType: .continuous,
            category: .lifestyle
        )

        let weekAgo = try #require(calendar.date(byAdding: .day, value: -7, to: today))
        let series = try service.extractTimeSeries(variable: variable, userId: user.id, dateRange: weekAgo ... today)

        #expect(series.isEmpty)
    }

    // MARK: - Paired Data Extraction

    @Test func pairedDataWithLag() throws {
        let context = try makeContext()
        let user = User()
        context.insert(user)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create daily logs for the past 5 days
        for i in 0 ..< 5 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let log = DailyLog(user: user, date: date)
            log.sleepHours = Float(6.0 + Double(i) * 0.5) // 6.0, 6.5, 7.0, 7.5, 8.0
            log.steps = (5000 + i * 1000)
            context.insert(log)
        }
        try context.save()

        let service = DataExtractionService(modelContext: context)

        let target = CorrelationVariable(
            id: "steps",
            displayName: "Steps",
            variableType: .continuous,
            category: .lifestyle
        )
        let factor = CorrelationVariable(
            id: "sleep_hours",
            displayName: "Sleep",
            variableType: .continuous,
            category: .lifestyle
        )

        let weekAgo = try #require(calendar.date(byAdding: .day, value: -7, to: today))
        let paired = try service.extractPairedData(
            target: target, factor: factor,
            userId: user.id, dateRange: weekAgo ... today,
            lagDays: 1
        )

        // With lag=1, we lose one day of data
        #expect(paired.sampleSize == 4)
        #expect(paired.targetValues.count == paired.factorValues.count)
    }

    // MARK: - Derived Variable Extraction

    @Test func extractTrainingDay() throws {
        let context = try makeContext()
        let (user, _) = try createTestWorkout(context: context, weight: 100, reps: 5, sets: 1)

        let service = DataExtractionService(modelContext: context)
        let variable = CorrelationVariable(
            id: "training_day",
            displayName: "Training Day",
            variableType: .binary,
            category: .derived
        )

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = try #require(calendar.date(byAdding: .day, value: -3, to: today))
        let series = try service.extractTimeSeries(
            variable: variable,
            userId: user.id,
            dateRange: threeDaysAgo ... today
        )

        // Should have entries for each day in range
        #expect(series.count >= 3)

        // Today should be a training day
        let todayEntry = series.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        #expect(todayEntry?.value == 1.0)
    }

    // MARK: - Helpers

    @discardableResult
    private func createTestWorkout(
        context: ModelContext,
        weight: Float,
        reps: Float,
        sets: Int
    ) throws -> (User, Exercise) {
        let user = User()
        context.insert(user)

        let exercise = Exercise(user: user, name: "Test Exercise", muscleGroups: ["Chest"])
        context.insert(exercise)

        let weightField = ExerciseFieldDefinition(
            exercise: exercise, name: "Weight", fieldType: "number",
            unit: "kg", systemKey: "weight", sortOrder: 0, isDefault: true
        )
        context.insert(weightField)

        let repsField = ExerciseFieldDefinition(
            exercise: exercise, name: "Reps", fieldType: "number",
            systemKey: "reps", sortOrder: 1, isDefault: true
        )
        context.insert(repsField)

        let today = Calendar.current.startOfDay(for: Date())
        let workout = Workout(user: user, date: today)
        workout.status = "completed"
        context.insert(workout)

        let workoutExercise = WorkoutExercise(workout: workout, exercise: exercise, sortOrder: 0)
        context.insert(workoutExercise)

        for i in 1 ... sets {
            let set = WorkoutSet(workoutExercise: workoutExercise, setNumber: i)
            context.insert(set)

            let weightValue = WorkoutSetValue(workoutSet: set, fieldDefinition: weightField, valueNumber: weight)
            context.insert(weightValue)

            let repsValue = WorkoutSetValue(workoutSet: set, fieldDefinition: repsField, valueNumber: reps)
            context.insert(repsValue)
        }

        try context.save()
        return (user, exercise)
    }
}
