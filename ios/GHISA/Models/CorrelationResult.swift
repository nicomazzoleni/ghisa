import Foundation
import SwiftData

@Model
final class CorrelationResult {
    @Attribute(.unique) var id: UUID
    var user: User
    var targetVariable: String
    var factorVariable: String
    var testMethod: String
    var lagDays: Int
    var effectSize: Float
    var pValue: Float
    var sampleSize: Int
    var meanHigh: Float?
    var meanLow: Float?
    var effectDescription: String
    var confidenceBadge: String
    var isSignificant: Bool
    var dataCompleteness: Float
    var computedAt: Date

    init(
        user: User,
        targetVariable: String,
        factorVariable: String,
        testMethod: String,
        lagDays: Int = 0,
        effectSize: Float,
        pValue: Float,
        sampleSize: Int,
        effectDescription: String,
        confidenceBadge: String,
        isSignificant: Bool,
        dataCompleteness: Float
    ) {
        self.id = UUID()
        self.user = user
        self.targetVariable = targetVariable
        self.factorVariable = factorVariable
        self.testMethod = testMethod
        self.lagDays = lagDays
        self.effectSize = effectSize
        self.pValue = pValue
        self.sampleSize = sampleSize
        self.effectDescription = effectDescription
        self.confidenceBadge = confidenceBadge
        self.isSignificant = isSignificant
        self.dataCompleteness = dataCompleteness
        self.computedAt = Date()
    }
}
