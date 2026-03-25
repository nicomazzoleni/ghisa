import Foundation

@MainActor
@Observable
final class FoodSearchViewModel {
    var searchText = ""
    var localResults: [FoodItem] = []
    var apiResults: [OpenFoodFactsProduct] = []
    var recentFoods: [FoodItem] = []
    var favoriteFoods: [FoodItem] = []
    var isSearching = false
    var errorMessage: String?

    private let nutritionService: NutritionService
    private let openFoodFactsService: OpenFoodFactsService
    private let user: User
    let nutrientDefinitions: [NutrientDefinition]

    private var searchTask: Task<Void, Never>?

    init(
        nutritionService: NutritionService,
        openFoodFactsService: OpenFoodFactsService,
        user: User,
        nutrientDefinitions: [NutrientDefinition]
    ) {
        self.nutritionService = nutritionService
        self.openFoodFactsService = openFoodFactsService
        self.user = user
        self.nutrientDefinitions = nutrientDefinitions
    }

    var isShowingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasNoResults: Bool {
        isShowingSearchResults && !isSearching && localResults.isEmpty && apiResults.isEmpty
    }

    func loadInitialData() {
        recentFoods = nutritionService.fetchRecentFoods(user: user)
        favoriteFoods = nutritionService.fetchFavoriteFoods(user: user)
    }

    func search() {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            localResults = []
            apiResults = []
            isSearching = false
            return
        }

        // Local search is instant
        localResults = nutritionService.searchLocalFoods(query: query, user: user)

        // Set before Task creation to prevent "No foods found" flash
        isSearching = true

        // API search is debounced
        searchTask = Task {
            // Debounce 400ms
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            do {
                let response = try await openFoodFactsService.searchFoods(query: query)
                guard !Task.isCancelled else { return }

                // Filter out products already cached locally, prioritize Latin-script names
                let localExternalIds = Set(localResults.compactMap(\.externalId))
                apiResults = response.products
                    .filter { product in
                        product.productName != nil && !localExternalIds.contains(product.code)
                    }
                    .sorted { lhs, rhs in
                        Self.rankProduct(lhs, query: query) < Self.rankProduct(rhs, query: query)
                    }
            } catch {
                guard !Task.isCancelled else { return }
                // Silent failure for API — local results still show
                apiResults = []
            }
            isSearching = false
        }
    }

    func cacheAndReturn(_ product: OpenFoodFactsProduct) -> FoodItem {
        let food = nutritionService.cacheFood(
            from: product,
            user: user,
            nutrientDefinitions: nutrientDefinitions
        )
        // Refresh recents after caching
        recentFoods = nutritionService.fetchRecentFoods(user: user)
        return food
    }

    func toggleFavorite(_ food: FoodItem) {
        nutritionService.toggleFavorite(food)
        favoriteFoods = nutritionService.fetchFavoriteFoods(user: user)
    }

    /// Lower rank = higher priority. Non-Latin names are penalized.
    /// Within the same script group: exact match > starts-with > contains > other.
    private static func rankProduct(_ product: OpenFoodFactsProduct, query: String) -> Int {
        let name = product.displayName.lowercased()
        let loweredQuery = query.lowercased()
        let scriptPenalty = product.displayName.isLatin ? 0 : 1000

        if name == loweredQuery { return scriptPenalty }
        if name.hasPrefix(loweredQuery) { return scriptPenalty + 1 }
        if name.contains(loweredQuery) { return scriptPenalty + 2 }
        return scriptPenalty + 3
    }
}
