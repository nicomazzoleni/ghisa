import Foundation
import SwiftData

@Model
final class MealCategory {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \MealEntry.mealCategory)
    var mealEntries: [MealEntry]

    @Relationship(deleteRule: .nullify, inverse: \MealTemplate.mealCategory)
    var mealTemplates: [MealTemplate]

    var createdAt: Date
    var updatedAt: Date

    init(
        user: User,
        name: String,
        sortOrder: Int,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.mealEntries = []
        self.mealTemplates = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
