import Foundation
import SwiftData

@Model
final class NutritionTarget {
    @Attribute(.unique) var id: UUID
    var user: User
    var nutrientDefinition: NutrientDefinition
    var targetValue: Float
    var updatedAt: Date

    init(
        user: User,
        nutrientDefinition: NutrientDefinition,
        targetValue: Float
    ) {
        self.id = UUID()
        self.user = user
        self.nutrientDefinition = nutrientDefinition
        self.targetValue = targetValue
        self.updatedAt = Date()
    }
}
