import Foundation
import SwiftData

@Model
final class MealTemplate {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var mealCategory: MealCategory?

    @Relationship(deleteRule: .cascade, inverse: \MealTemplateItem.mealTemplate)
    var items: [MealTemplateItem]

    var createdAt: Date
    var updatedAt: Date

    init(user: User, name: String, mealCategory: MealCategory? = nil) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.mealCategory = mealCategory
        self.items = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
