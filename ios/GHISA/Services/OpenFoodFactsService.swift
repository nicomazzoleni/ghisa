import Foundation

// MARK: - Response Types

struct OpenFoodFactsResponse: Decodable {
    let count: Int
    let page: Int
    let pageSize: Int
    let products: [OpenFoodFactsProduct]

    enum CodingKeys: String, CodingKey {
        case count
        case page
        case pageSize = "page_size"
        case products
    }

    init(count: Int, page: Int, pageSize: Int, products: [OpenFoodFactsProduct]) {
        self.count = count
        self.page = page
        self.pageSize = pageSize
        self.products = products
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // OFF cgi/search.pl returns count/page as strings; v2 returns ints
        self.count = try (try? container.decode(Int.self, forKey: .count))
            ?? Int(container.decode(String.self, forKey: .count)) ?? 0
        self.page = try (try? container.decode(Int.self, forKey: .page))
            ?? Int(container.decode(String.self, forKey: .page)) ?? 1
        self.pageSize = try (try? container.decode(Int.self, forKey: .pageSize))
            ?? Int(container.decode(String.self, forKey: .pageSize)) ?? 0
        self.products = (try? container.decode([OpenFoodFactsProduct].self, forKey: .products)) ?? []
    }
}

struct OpenFoodFactsProduct: Decodable, Identifiable {
    let code: String
    let productName: String?
    let brands: String?
    let servingQuantity: Float?
    let servingSize: String?
    let nutriments: OpenFoodFactsNutriments?

    var id: String {
        code
    }

    var displayName: String {
        productName ?? "Unknown Product"
    }

    var displayBrand: String? {
        let trimmed = brands?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingQuantity = "serving_quantity"
        case servingSize = "serving_size"
        case nutriments
    }
}

struct OpenFoodFactsNutriments: Decodable {
    let energyKcal100g: Float?
    let proteins100g: Float?
    let carbohydrates100g: Float?
    let fat100g: Float?
    let fiber100g: Float?
    let sugars100g: Float?
    let sodium100g: Float?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
        case sodium100g = "sodium_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.energyKcal100g = Self.decodeFlexibleFloat(container: container, key: .energyKcal100g)
        self.proteins100g = Self.decodeFlexibleFloat(container: container, key: .proteins100g)
        self.carbohydrates100g = Self.decodeFlexibleFloat(container: container, key: .carbohydrates100g)
        self.fat100g = Self.decodeFlexibleFloat(container: container, key: .fat100g)
        self.fiber100g = Self.decodeFlexibleFloat(container: container, key: .fiber100g)
        self.sugars100g = Self.decodeFlexibleFloat(container: container, key: .sugars100g)
        self.sodium100g = Self.decodeFlexibleFloat(container: container, key: .sodium100g)
    }

    /// OFF returns numeric fields as either numbers or strings depending on the product.
    private static func decodeFlexibleFloat(
        container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Float? {
        if let value = try? container.decode(Float.self, forKey: key) {
            return value
        }
        if let str = try? container.decode(String.self, forKey: key) {
            return Float(str)
        }
        return nil
    }

    /// Convert per-100g values to per-serving values given a serving size in grams.
    func perServing(servingSizeG: Float) -> [String: Float] {
        let factor = servingSizeG / 100.0
        var result: [String: Float] = [:]
        let mapping: [(String, Float?)] = [
            ("energy-kcal", energyKcal100g),
            ("proteins", proteins100g),
            ("carbohydrates", carbohydrates100g),
            ("fat", fat100g),
            ("fiber", fiber100g),
            ("sugars", sugars100g),
            ("sodium", sodium100g),
        ]
        for (key, value) in mapping {
            if let value { result[key] = value * factor }
        }
        return result
    }
}

// MARK: - Helpers

extension String {
    /// True when the majority of letter characters use Latin script.
    var isLatin: Bool {
        let letters = unicodeScalars.prefix(30).filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return true }
        let latinCount = letters.count(where: { CharacterSet.latinLetters.contains($0) })
        return latinCount > letters.count / 2
    }
}

extension CharacterSet {
    /// Latin letters only (Basic Latin through Latin Extended-B).
    fileprivate static let latinLetters: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "A" ... "Z")
        set.insert(charactersIn: "a" ... "z")
        // Latin-1 Supplement + Latin Extended-A/B (accented characters)
        set.insert(charactersIn: "\u{00C0}" ... "\u{024F}")
        return set
    }()
}

// MARK: - Service

final class OpenFoodFactsService: Sendable {
    private let baseURL = AppConfig.OpenFoodFacts.baseURL

    init() {}

    func searchFoods(query: String, page: Int = 1) async throws -> OpenFoodFactsResponse {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return OpenFoodFactsResponse(count: 0, page: 1, pageSize: 0, products: [])
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("cgi/search.pl"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmed),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "lc", value: "en"),
            URLQueryItem(name: "page_size", value: String(AppConfig.OpenFoodFacts.pageSize)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "fields", value: "code,product_name,brands,serving_quantity,serving_size,nutriments"),
        ]

        guard let url = components?.url else {
            throw AppError.network(underlying: URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.setValue("GHISA/1.0 (iOS; github.com/ghisa-app)", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            return try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProduct? {
        let url = baseURL.appendingPathComponent("api/v0/product/\(barcode).json")

        var request = URLRequest(url: url)
        request.setValue("GHISA/1.0 (iOS; github.com/ghisa-app)", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        struct SingleProductResponse: Decodable {
            let status: Int
            let product: OpenFoodFactsProduct?
        }

        let response = try JSONDecoder().decode(SingleProductResponse.self, from: data)
        return response.status == 1 ? response.product : nil
    }
}
