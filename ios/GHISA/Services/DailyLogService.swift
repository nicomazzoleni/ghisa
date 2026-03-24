import Foundation
import SwiftData

@Observable
final class DailyLogService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Daily Log

    func fetchOrCreateDailyLog(for date: Date, user: User) -> DailyLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let userId = user.id
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.user.id == userId && log.date >= startOfDay && log.date < nextDay
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newLog = DailyLog(user: user, date: startOfDay)
        modelContext.insert(newLog)
        try? modelContext.save()
        return newLog
    }

    // MARK: - HealthKit Data

    func updateHealthKitData(_ data: HealthKitDailyData, for dailyLog: DailyLog) {
        dailyLog.sleepHours = data.sleepHours ?? dailyLog.sleepHours
        dailyLog.sleepDeepMinutes = data.sleepDeepMinutes ?? dailyLog.sleepDeepMinutes
        dailyLog.sleepCoreMinutes = data.sleepCoreMinutes ?? dailyLog.sleepCoreMinutes
        dailyLog.sleepRemMinutes = data.sleepRemMinutes ?? dailyLog.sleepRemMinutes
        dailyLog.steps = data.steps ?? dailyLog.steps
        dailyLog.restingHeartRate = data.restingHeartRate ?? dailyLog.restingHeartRate
        dailyLog.hrv = data.hrv ?? dailyLog.hrv
        dailyLog.activeEnergyKcal = data.activeEnergyKcal ?? dailyLog.activeEnergyKcal
        dailyLog.walkingDistanceKm = data.walkingDistanceKm ?? dailyLog.walkingDistanceKm
        dailyLog.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Custom Fields

    func addCustomField(name: String, fieldType: String, unit: String?, user: User) throws -> DailyLogFieldDefinition {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AppError.validation(message: "Field name cannot be empty.")
        }

        // Check for duplicates
        let userId = user.id
        let descriptor = FetchDescriptor<DailyLogFieldDefinition>(
            predicate: #Predicate<DailyLogFieldDefinition> { field in
                field.user.id == userId && field.isActive
            }
        )
        let existingFields = (try? modelContext.fetch(descriptor)) ?? []
        if existingFields.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw AppError.validation(message: "A field named \"\(trimmedName)\" already exists.")
        }

        let sortOrder = existingFields.count
        let field = DailyLogFieldDefinition(
            user: user,
            name: trimmedName,
            fieldType: fieldType,
            unit: unit,
            sortOrder: sortOrder
        )
        modelContext.insert(field)
        try modelContext.save()
        return field
    }

    func removeCustomField(_ field: DailyLogFieldDefinition) throws {
        modelContext.delete(field)
        try modelContext.save()
    }

    func updateFieldValue(
        dailyLog: DailyLog,
        field: DailyLogFieldDefinition,
        numberValue: Float? = nil,
        textValue: String? = nil,
        toggleValue: Bool? = nil
    ) {
        // Find existing value or create new
        if let existing = dailyLog.values.first(where: { $0.fieldDefinition.id == field.id }) {
            existing.valueNumber = numberValue
            existing.valueText = textValue
            existing.valueToggle = toggleValue
        } else {
            let value = DailyLogValue(
                dailyLog: dailyLog,
                fieldDefinition: field,
                valueNumber: numberValue,
                valueText: textValue,
                valueToggle: toggleValue
            )
            modelContext.insert(value)
        }
        try? modelContext.save()
    }

    func getActiveFields(for user: User) -> [DailyLogFieldDefinition] {
        let userId = user.id
        let descriptor = FetchDescriptor<DailyLogFieldDefinition>(
            predicate: #Predicate<DailyLogFieldDefinition> { field in
                field.user.id == userId && field.isActive
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
