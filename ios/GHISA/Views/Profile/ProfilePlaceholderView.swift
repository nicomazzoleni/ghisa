import SwiftData
import SwiftUI

struct ProfilePlaceholderView: View {
    @Environment(\.modelContext) private var modelContext

    #if DEBUG
    @State private var isSeeding = false
    @State private var seedResult: SeedResult?

    private enum SeedResult: Identifiable {
        case success(Int)
        case error(String)
        case alreadyExists
        case nutritionSuccess(Int)
        case nutritionAlreadyExists

        var id: String {
            switch self {
                case .success: "success"
                case .error: "error"
                case .alreadyExists: "alreadyExists"
                case .nutritionSuccess: "nutritionSuccess"
                case .nutritionAlreadyExists: "nutritionAlreadyExists"
            }
        }
    }
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Background.base.ignoresSafeArea()

                #if DEBUG
                List {
                    Section {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.Text.tertiary)
                            Text("Profile")
                                .font(Theme.Typography.sectionHeader)
                                .foregroundStyle(Theme.Text.primary)
                            Text("Coming soon")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Text.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.lg)
                    }

                    Section("Debug — Data Seeder") {
                        Button {
                            seedTrainingData()
                        } label: {
                            HStack {
                                Label("Seed 1 Year Training Data", systemImage: "dumbbell")
                                Spacer()
                                if isSeeding {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isSeeding)

                        Button(role: .destructive) {
                            clearTrainingData()
                        } label: {
                            Label("Clear Training Data", systemImage: "trash")
                        }
                        .disabled(isSeeding)

                        Button {
                            seedNutritionData()
                        } label: {
                            HStack {
                                Label("Seed 1 Year Nutrition Data", systemImage: "fork.knife")
                                Spacer()
                                if isSeeding {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isSeeding)

                        Button(role: .destructive) {
                            clearNutritionData()
                        } label: {
                            Label("Clear Nutrition Data", systemImage: "trash")
                        }
                        .disabled(isSeeding)
                    }
                }
                .scrollContentBackground(.hidden)
                .alert(item: $seedResult) { result in
                    switch result {
                        case let .success(count):
                            Alert(
                                title: Text("Seeding Complete"),
                                message: Text("Created \(count) workouts with realistic 1-year progression."),
                                dismissButton: .default(Text("OK"))
                            )
                        case let .error(message):
                            Alert(
                                title: Text("Seeding Failed"),
                                message: Text(message),
                                dismissButton: .default(Text("OK"))
                            )
                        case .alreadyExists:
                            Alert(
                                title: Text("Data Already Exists"),
                                message: Text("Seeded training data already exists. Clear it first, then try again."),
                                dismissButton: .default(Text("OK"))
                            )
                        case let .nutritionSuccess(count):
                            Alert(
                                title: Text("Seeding Complete"),
                                message: Text("Created \(count) meal entries with realistic 1-year nutrition data."),
                                dismissButton: .default(Text("OK"))
                            )
                        case .nutritionAlreadyExists:
                            Alert(
                                title: Text("Data Already Exists"),
                                message: Text("Seeded nutrition data already exists. Clear it first, then try again."),
                                dismissButton: .default(Text("OK"))
                            )
                    }
                }
                #else
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Text.tertiary)
                    Text("Profile")
                        .font(Theme.Typography.sectionHeader)
                        .foregroundStyle(Theme.Text.primary)
                    Text("Coming soon")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Text.tertiary)
                }
                #endif
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    #if DEBUG
    private func seedTrainingData() {
        let service = DataSeedService(modelContext: modelContext)
        do {
            if try service.hasSeededTrainingData() {
                seedResult = .alreadyExists
                return
            }
        } catch {
            seedResult = .error(error.localizedDescription)
            return
        }

        isSeeding = true
        Task {
            do {
                let count = try await service.seedTrainingData()
                seedResult = .success(count)
            } catch {
                seedResult = .error(error.localizedDescription)
            }
            isSeeding = false
        }
    }

    private func clearTrainingData() {
        let service = DataSeedService(modelContext: modelContext)
        do {
            try service.clearTrainingData()
            seedResult = .success(0)
        } catch {
            seedResult = .error(error.localizedDescription)
        }
    }

    private func seedNutritionData() {
        let service = DataSeedService(modelContext: modelContext)
        do {
            if try service.hasSeededNutritionData() {
                seedResult = .nutritionAlreadyExists
                return
            }
        } catch {
            seedResult = .error(error.localizedDescription)
            return
        }

        isSeeding = true
        Task {
            do {
                let count = try await service.seedNutritionData()
                seedResult = .nutritionSuccess(count)
            } catch {
                seedResult = .error(error.localizedDescription)
            }
            isSeeding = false
        }
    }

    private func clearNutritionData() {
        let service = DataSeedService(modelContext: modelContext)
        do {
            try service.clearNutritionData()
            seedResult = .nutritionSuccess(0)
        } catch {
            seedResult = .error(error.localizedDescription)
        }
    }
    #endif
}
