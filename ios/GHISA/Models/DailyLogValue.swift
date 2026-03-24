import Foundation
import SwiftData

@Model
final class DailyLogValue {
    @Attribute(.unique) var id: UUID
    var dailyLog: DailyLog
    var fieldDefinition: DailyLogFieldDefinition
    var valueNumber: Float?
    var valueText: String?
    var valueToggle: Bool?

    init(
        dailyLog: DailyLog,
        fieldDefinition: DailyLogFieldDefinition,
        valueNumber: Float? = nil,
        valueText: String? = nil,
        valueToggle: Bool? = nil
    ) {
        self.id = UUID()
        self.dailyLog = dailyLog
        self.fieldDefinition = fieldDefinition
        self.valueNumber = valueNumber
        self.valueText = valueText
        self.valueToggle = valueToggle
    }
}
