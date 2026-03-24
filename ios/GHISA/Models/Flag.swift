import Foundation
import SwiftData

@Model
final class Flag {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var color: String
    var icon: String?
    var scope: String

    @Relationship(deleteRule: .cascade, inverse: \FlagAssignment.flag)
    var assignments: [FlagAssignment]

    var createdAt: Date

    init(
        user: User,
        name: String,
        color: String,
        icon: String? = nil,
        scope: String
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.color = color
        self.icon = icon
        self.scope = scope
        self.assignments = []
        self.createdAt = Date()
    }
}
