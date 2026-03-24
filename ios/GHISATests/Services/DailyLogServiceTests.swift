import Foundation
@testable import GHISA
import SwiftData
import Testing

struct DailyLogServiceTests {
    @Test("fetchOrCreate creates new DailyLog for date")
    func fetchOrCreateNew() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let log = service.fetchOrCreateDailyLog(for: Date(), user: user)
        #expect(log.user.id == user.id)
    }

    @Test("fetchOrCreate returns existing DailyLog for same date")
    func fetchOrCreateExisting() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let date = Calendar.current.startOfDay(for: Date())
        let first = service.fetchOrCreateDailyLog(for: date, user: user)
        let second = service.fetchOrCreateDailyLog(for: date, user: user)
        #expect(first.id == second.id)
    }

    @Test("updateHealthKitData maps all fields")
    func updateHealthKitData() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let log = service.fetchOrCreateDailyLog(for: Date(), user: user)
        let data = HealthKitDailyData(
            sleepHours: 7.5,
            sleepDeepMinutes: 90,
            sleepCoreMinutes: 180,
            sleepRemMinutes: 60,
            steps: 10000,
            restingHeartRate: 58,
            hrv: 45.2,
            activeEnergyKcal: 350.0,
            walkingDistanceKm: 6.5
        )

        service.updateHealthKitData(data, for: log)

        #expect(log.sleepHours == 7.5)
        #expect(log.sleepDeepMinutes == 90)
        #expect(log.sleepCoreMinutes == 180)
        #expect(log.sleepRemMinutes == 60)
        #expect(log.steps == 10000)
        #expect(log.restingHeartRate == 58)
        #expect(log.hrv == 45.2)
        #expect(log.activeEnergyKcal == 350.0)
        #expect(log.walkingDistanceKm == 6.5)
    }

    @Test("addCustomField creates field successfully")
    func addCustomFieldSuccess() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let field = try service.addCustomField(name: "Body Weight", fieldType: "number", unit: "kg", user: user)
        #expect(field.name == "Body Weight")
        #expect(field.fieldType == "number")
        #expect(field.unit == "kg")
        #expect(field.isActive)
        #expect(field.sortOrder == 0)
    }

    @Test("addCustomField rejects empty name")
    func addCustomFieldEmptyName() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        #expect(throws: AppError.self) {
            _ = try service.addCustomField(name: "  ", fieldType: "number", unit: nil, user: user)
        }
    }

    @Test("addCustomField rejects duplicate name")
    func addCustomFieldDuplicate() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        _ = try service.addCustomField(name: "Steps", fieldType: "number", unit: nil, user: user)

        #expect(throws: AppError.self) {
            _ = try service.addCustomField(name: "steps", fieldType: "number", unit: nil, user: user)
        }
    }

    @Test("removeCustomField deletes field")
    func removeCustomField() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let field = try service.addCustomField(name: "Mood", fieldType: "text", unit: nil, user: user)
        try service.removeCustomField(field)

        let fields = service.getActiveFields(for: user)
        #expect(fields.isEmpty)
    }

    @Test("updateFieldValue creates new value")
    func updateFieldValueNew() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let log = service.fetchOrCreateDailyLog(for: Date(), user: user)
        let field = try service.addCustomField(name: "Weight", fieldType: "number", unit: "kg", user: user)

        service.updateFieldValue(dailyLog: log, field: field, numberValue: 75.5)

        let value = log.values.first(where: { $0.fieldDefinition.id == field.id })
        #expect(value?.valueNumber == 75.5)
    }

    @Test("updateFieldValue updates existing value")
    func updateFieldValueExisting() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        let log = service.fetchOrCreateDailyLog(for: Date(), user: user)
        let field = try service.addCustomField(name: "Weight", fieldType: "number", unit: "kg", user: user)

        service.updateFieldValue(dailyLog: log, field: field, numberValue: 75.5)
        service.updateFieldValue(dailyLog: log, field: field, numberValue: 76.0)

        let values = log.values.filter { $0.fieldDefinition.id == field.id }
        #expect(values.count == 1)
        #expect(values.first?.valueNumber == 76.0)
    }

    @Test("getActiveFields returns sorted, active-only fields")
    func getActiveFieldsSorted() throws {
        let (context, user) = try TestModelContainer.makeContext()
        let service = DailyLogService(modelContext: context)

        _ = try service.addCustomField(name: "AAA", fieldType: "number", unit: nil, user: user)
        _ = try service.addCustomField(name: "BBB", fieldType: "text", unit: nil, user: user)

        let fields = service.getActiveFields(for: user)
        #expect(fields.count == 2)
        #expect(fields[0].name == "AAA")
        #expect(fields[1].name == "BBB")
    }
}
