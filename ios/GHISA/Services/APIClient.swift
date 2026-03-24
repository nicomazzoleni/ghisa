import Foundation

@Observable
final class APIClient {
    private let baseURL = AppConfig.API.baseURL

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    /// Generic request method
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil
    ) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(body)
        }

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw AppError.network(underlying: error)
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(APIResponse<T>.self, from: data)
            if let responseData = response.data, response.success {
                return responseData
            }
            let message = response.error?.message ?? "Unknown error"
            throw AppError.network(underlying: NSError(
                domain: "API",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    /// Standard API response envelope
    struct APIResponse<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: APIErrorResponse?
        let meta: Meta?
    }

    struct APIErrorResponse: Decodable {
        let code: String
        let message: String
    }

    struct Meta: Decodable {
        let page: Int?
        let totalPages: Int?
        let totalCount: Int?
    }
}
