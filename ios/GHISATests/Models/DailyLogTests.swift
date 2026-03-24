import Foundation
@testable import GHISA
import Testing

struct DailyLogTests {
    @Test func dailyLogDefaults() {
        let user = User()
        let log = DailyLog(user: user, date: Date())
        #expect(log.sleepHours == nil)
        #expect(log.steps == nil)
        #expect(log.hrv == nil)
        #expect(log.values.isEmpty)
    }

    @Test func dailyLogFieldDefinitionDefaults() {
        let user = User()
        let field = DailyLogFieldDefinition(
            user: user,
            name: "Body Weight",
            fieldType: "number",
            unit: "kg",
            systemKey: "body_weight",
            sortOrder: 0,
            isDefault: true
        )
        #expect(field.name == "Body Weight")
        #expect(field.systemKey == "body_weight")
        #expect(field.isActive == true)
        #expect(field.isDefault == true)
    }
}
