import SwiftUI

struct FoodSearchView: View {
    @Bindable var viewModel: FoodSearchViewModel
    let mealCategory: MealCategory
    let nutritionService: NutritionService
    let user: User
    let date: Date
    let nutrientDefinitions: [NutrientDefinition]
    let onMealAdded: () -> Void

    @State private var selectedFood: FoodItem?
    @State private var showCreateCustomFood = false

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isShowingSearchResults {
                        searchResults
                    } else {
                        browseContent
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .background(Theme.Background.base)
        .onAppear {
            viewModel.loadInitialData()
        }
        .sheet(item: $selectedFood) { food in
            FoodDetailSheet(
                food: food,
                mealCategory: mealCategory,
                nutrientDefinitions: nutrientDefinitions,
                nutritionService: nutritionService,
                user: user,
                date: date,
                onMealAdded: onMealAdded
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCreateCustomFood) {
            CreateCustomFoodView(
                nutritionService: nutritionService,
                nutrientDefinitions: nutrientDefinitions,
                user: user,
                onFoodCreated: { food in
                    selectedFood = food
                }
            )
        }
    }

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Text.tertiary)

            TextField("Search foods...", text: $viewModel.searchText)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)
                .autocorrectionDisabled()
                .onChange(of: viewModel.searchText) {
                    viewModel.search()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Background.elevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var searchResults: some View {
        if !viewModel.localResults.isEmpty {
            sectionLabel("Your Foods")
            ForEach(viewModel.localResults, id: \.id) { food in
                foodItemRow(food)
            }
        }

        if !viewModel.apiResults.isEmpty {
            sectionLabel("From Open Food Facts")
            ForEach(viewModel.apiResults) { product in
                apiProductRow(product)
            }
        }

        if viewModel.isSearching {
            HStack {
                Spacer()
                ProgressView()
                    .padding(Theme.Spacing.lg)
                Spacer()
            }
        }

        if viewModel.hasNoResults {
            VStack(spacing: Theme.Spacing.sm) {
                Text("No foods found")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.secondary)

                Button("Create Custom Food") {
                    showCreateCustomFood = true
                }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Accent.primary)
            }
            .padding(.vertical, Theme.Spacing.xl)
            .frame(maxWidth: .infinity)
        }

        createCustomButton
    }

    @ViewBuilder
    private var browseContent: some View {
        if !viewModel.favoriteFoods.isEmpty {
            sectionLabel("Favorites")
            ForEach(viewModel.favoriteFoods, id: \.id) { food in
                foodItemRow(food)
            }
        }

        if !viewModel.recentFoods.isEmpty {
            sectionLabel("Recent")
            ForEach(viewModel.recentFoods, id: \.id) { food in
                foodItemRow(food)
            }
        }

        if viewModel.recentFoods.isEmpty, viewModel.favoriteFoods.isEmpty {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Text.tertiary)
                Text("Search for a food or create your own")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.secondary)
            }
            .padding(.vertical, Theme.Spacing.xxl)
            .frame(maxWidth: .infinity)
        }

        createCustomButton
    }

    private var createCustomButton: some View {
        Button {
            showCreateCustomFood = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Theme.Accent.primary)
                Text("Create Custom Food")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Accent.primary)
                Spacer()
            }
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private func foodItemRow(_ food: FoodItem) -> some View {
        Button {
            selectedFood = food
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.primary)
                        .lineLimit(1)

                    if let brand = food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(caloriesLabel(for: food))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private func apiProductRow(_ product: OpenFoodFactsProduct) -> some View {
        Button {
            let food = viewModel.cacheAndReturn(product)
            selectedFood = food
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.primary)
                        .lineLimit(1)

                    if let brand = product.displayBrand {
                        Text(brand)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Text.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let kcal = product.nutriments?.energyKcal100g {
                    Text("\(Int(kcal)) kcal/100g")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Text.secondary)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Text.tertiary)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func caloriesLabel(for food: FoodItem) -> String {
        let calDef = viewModel.nutrientDefinitions.first { $0.name.lowercased() == "calories" }
        guard let calDef else { return "" }
        let cal = food.nutrients.first { $0.nutrientDefinition.id == calDef.id }
        guard let value = cal?.valuePerServing else { return "" }
        return "\(Int(value)) kcal"
    }
}
