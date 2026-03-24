import Foundation

enum AppError: LocalizedError {
    case network(underlying: Error)
    case database(underlying: Error)
    case healthKit(underlying: Error)
    case validation(message: String)
    case sync(underlying: Error)

    var errorDescription: String? {
        switch self {
            case .network: "A network error occurred. Please try again."
            case .database: "A data error occurred. Please try again."
            case .healthKit: "Could not access health data."
            case let .validation(message): message
            case .sync: "Sync failed. Your data is safe locally."
        }
    }
}
