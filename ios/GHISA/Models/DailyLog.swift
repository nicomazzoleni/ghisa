import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID
    var user: User
    var date: Date
    var sleepHours: Float?
    var sleepDeepMinutes: Int?
    var sleepCoreMinutes: Int?
    var sleepRemMinutes: Int?
    var steps: Int?
    var restingHeartRate: Int?
    var hrv: Float?
    var activeEnergyKcal: Float?
    var walkingDistanceKm: Float?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \DailyLogValue.dailyLog)
    var values: [DailyLogValue]

    var createdAt: Date
    var updatedAt: Date

    init(user: User, date: Date) {
        self.id = UUID()
        self.user = user
        self.date = date
        self.values = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
