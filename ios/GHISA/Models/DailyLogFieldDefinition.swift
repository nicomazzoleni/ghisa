import Foundation
import SwiftData

@Model
final class DailyLogFieldDefinition {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var fieldType: String
    var unit: String?
    var systemKey: String?
    var sortOrder: Int
    var isActive: Bool
    var isDefault: Bool

    @Relationship(deleteRule: .cascade, inverse: \DailyLogValue.fieldDefinition)
    var dailyLogValues: [DailyLogValue]

    var createdAt: Date

    init(
        user: User,
        name: String,
        fieldType: String,
        unit: String? = nil,
        systemKey: String? = nil,
        sortOrder: Int,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.fieldType = fieldType
        self.unit = unit
        self.systemKey = systemKey
        self.sortOrder = sortOrder
        self.isActive = true
        self.isDefault = isDefault
        self.dailyLogValues = []
        self.createdAt = Date()
    }
}
