import Foundation
@testable import GHISA
import Testing

struct AppErrorTests {
    @Test func errorDescriptions() {
        let networkError = AppError.network(underlying: NSError(domain: "test", code: 0))
        #expect(networkError.errorDescription == "A network error occurred. Please try again.")

        let dbError = AppError.database(underlying: NSError(domain: "test", code: 0))
        #expect(dbError.errorDescription == "A data error occurred. Please try again.")

        let hkError = AppError.healthKit(underlying: NSError(domain: "test", code: 0))
        #expect(hkError.errorDescription == "Could not access health data.")

        let validationError = AppError.validation(message: "Invalid input")
        #expect(validationError.errorDescription == "Invalid input")

        let syncError = AppError.sync(underlying: NSError(domain: "test", code: 0))
        #expect(syncError.errorDescription == "Sync failed. Your data is safe locally.")
    }
}
