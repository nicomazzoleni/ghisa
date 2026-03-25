import Foundation
import SwiftData

@Observable
final class DailyLogViewModel {
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var currentDailyLog: DailyLog?
    var healthKitData: HealthKitDailyData?
    var customFields: [DailyLogFieldDefinition] = []
    var showAddFieldSheet = false
    var isLoadingHealthKit = false
    var isImportingHistory = false
    var errorMessage: String?

    // Nutrition state
    var mealCategories: [MealCategory] = []
    var mealEntriesByCategory: [UUID: [MealEntry]] = [:]
    var dailyNutrientTotals: [UUID: Float] = [:]
    var nutrientDefinitions: [NutrientDefinition] = []
    var showAddMealSheet = false
    var selectedMealCategory: MealCategory?

    private let dailyLogService: DailyLogService
    private let healthKitService: HealthKitService
    private let nutritionService: NutritionService
    private let user: User

    var healthKitAuthRequested: Bool {
        healthKitService.isAuthorized
    }

    init(
        dailyLogService: DailyLogService,
        healthKitService: HealthKitService,
        nutritionService: NutritionService,
        user: User
    ) {
        self.dailyLogService = dailyLogService
        self.healthKitService = healthKitService
        self.nutritionService = nutritionService
        self.user = user
    }

    // MARK: - Date Navigation

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var canGoForward: Bool {
        !isToday
    }

    var formattedDate: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    func goToNextDay() {
        guard canGoForward else { return }
        if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: next)
        }
    }

    func goToPreviousDay() {
        if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: prev)
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        currentDailyLog = dailyLogService.fetchOrCreateDailyLog(for: selectedDate, user: user)
        customFields = dailyLogService.getActiveFields(for: user)
        loadNutritionData()

        if healthKitAuthRequested {
            isLoadingHealthKit = true
            do {
                healthKitData = try await healthKitService.fetchDailyData(for: selectedDate)
                if let data = healthKitData, let log = currentDailyLog {
                    dailyLogService.updateHealthKitData(data, for: log)
                }
            } catch {
                // Silent failure — HK data is supplementary
                healthKitData = nil
            }
            isLoadingHealthKit = false
        }
    }

    // MARK: - HealthKit Auth

    func requestHealthKitAccess() async {
        do {
            try await healthKitService.requestAuthorization()
            isImportingHistory = true
            if let modelContext = currentDailyLog?.modelContext {
                try await healthKitService.performHistoricalImport(modelContext: modelContext, user: user)
            }
            isImportingHistory = false
            await loadData()
        } catch {
            isImportingHistory = false
            errorMessage = "Could not connect to Apple Health."
        }
    }

    // MARK: - Custom Fields

    func addField(name: String, fieldType: String, unit: String?) {
        do {
            _ = try dailyLogService.addCustomField(name: name, fieldType: fieldType, unit: unit, user: user)
            customFields = dailyLogService.getActiveFields(for: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeField(_ field: DailyLogFieldDefinition) {
        do {
            try dailyLogService.removeCustomField(field)
            customFields = dailyLogService.getActiveFields(for: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFieldValue(
        field: DailyLogFieldDefinition,
        numberValue: Float? = nil,
        textValue: String? = nil,
        toggleValue: Bool? = nil
    ) {
        guard let log = currentDailyLog else { return }
        dailyLogService.updateFieldValue(
            dailyLog: log,
            field: field,
            numberValue: numberValue,
            textValue: textValue,
            toggleValue: toggleValue
        )
    }

    func currentValue(for field: DailyLogFieldDefinition) -> DailyLogValue? {
        currentDailyLog?.values.first(where: { $0.fieldDefinition.id == field.id })
    }

    // MARK: - Nutrition

    var nutritionSummaryText: String {
        guard !nutrientDefinitions.isEmpty else { return "" }
        let parts = nutrientDefinitions.compactMap { def -> String? in
            let total = dailyNutrientTotals[def.id] ?? 0
            let formatted = total < 10 ? String(format: "%.1f", total) : String(Int(total))
            return "\(formatted)\(def.unit == "kcal" ? "" : "g") \(abbreviatedName(def))"
        }
        return parts.joined(separator: " · ")
    }

    func loadNutritionData() {
        nutrientDefinitions = nutritionService.fetchVisibleNutrientDefinitions(for: user)
        mealCategories = nutritionService.fetchMealCategories(for: user)

        let entries = nutritionService.fetchMealEntries(for: selectedDate, user: user)
        mealEntriesByCategory = nutritionService.groupEntriesByCategory(entries, categories: mealCategories)
        dailyNutrientTotals = nutritionService.calculateDailyTotals(
            entries: entries,
            nutrientDefinitions: nutrientDefinitions
        )
    }

    func deleteMealEntry(_ entry: MealEntry) {
        nutritionService.deleteMealEntry(entry)
        loadNutritionData()
    }

    func updateMealEntryQuantity(_ entry: MealEntry, quantity: Float) {
        do {
            try nutritionService.updateMealEntryQuantity(entry, quantity: quantity)
            loadNutritionData()
        } catch {
            errorMessage = "Could not update quantity."
        }
    }

    func openAddMealSheet(for category: MealCategory) {
        selectedMealCategory = category
        showAddMealSheet = true
    }

    func onMealAdded() {
        loadNutritionData()
    }

    private func abbreviatedName(_ def: NutrientDefinition) -> String {
        switch def.name.lowercased() {
            case "calories": "kcal"
            case "protein": "P"
            case "carbs", "carbohydrates": "C"
            case "fat": "F"
            default: def.name
        }
    }
}
