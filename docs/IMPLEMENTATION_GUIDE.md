# GHISA — Implementation Guide: Foundation Setup

Everything that needs to be built before feature development can begin. Each step includes exact file paths, what the file should contain, and acceptance criteria.

> **Scope:** This guide covers the **scaffold only** — the empty-but-runnable app shell, all SwiftData models, core services (stubs), theming, and the backend skeleton. No feature logic.

> **V1 Note:** Per the PRD, V1 is **local-only** (no backend, no auth, no sync). The backend scaffold is included here for completeness and so it's ready when needed, but iOS is the priority. Everything under "Phase 5: Backend Scaffold" can be deferred.

---

## Phase 1: Xcode Project & App Shell

### 1.1 Create the Xcode Project

**Goal:** A buildable, runnable SwiftUI app that launches to a blank screen on iPhone Simulator.

**Steps:**
1. Create a new Xcode project:
   - Template: **App** (under iOS)
   - Product Name: `GHISA`
   - Team: Personal team (or None for now)
   - Organization Identifier: `com.ghisa` (placeholder — easy to change later)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we'll add SwiftData manually for full control)
   - Uncheck "Include Tests" — we'll add test targets manually with the right structure
   - Location: `ios/` directory (the `.xcodeproj` should land at `ios/GHISA.xcodeproj`)
2. Configure project settings:
   - Minimum Deployments: **iOS 17.0**
   - Supported Destinations: **iPhone** only (remove iPad)
   - Device Orientation: **Portrait** only (lock it — gym app, nobody uses landscape)
   - Display Name: use a string constant, not a hardcoded literal (for easy rename)
3. Add capabilities:
   - **HealthKit** — check "Clinical Health Records" off, just base HealthKit
4. Verify: `⌘R` → blank app launches on iPhone 16 Simulator

**Resulting files:**
```
ios/
├── GHISA.xcodeproj/
└── GHISA/
    ├── GHISAApp.swift          ← app entry point (created by Xcode)
    ├── ContentView.swift        ← placeholder (will be replaced)
    ├── Assets.xcassets/         ← asset catalog
    ├── Preview Content/         ← preview assets
    └── Info.plist               ← (if Xcode generates one; may be in project settings instead)
```

**Acceptance criteria:**
- [ ] Project builds with zero errors and zero warnings
- [ ] App launches on iPhone 16 Simulator
- [ ] Minimum deployment target is iOS 17.0
- [ ] Only iPhone is in Supported Destinations (no iPad)
- [ ] HealthKit capability is added (visible in Signing & Capabilities tab)
- [ ] Portrait orientation only

---

### 1.2 Create the Folder Structure

**Goal:** Establish the canonical directory layout from CLAUDE.md so every file has a clear home.

**Create these groups/folders inside `ios/GHISA/`:**

```
GHISA/
├── App/                    ← app entry point, app-level config
├── Models/                 ← SwiftData @Model classes
├── Views/
│   ├── Insights/           ← home tab — correlation dashboard
│   ├── Training/           ← workout logging
│   ├── DailyLog/           ← nutrition + lifestyle
│   ├── Profile/            ← profile sheet
│   └── Components/         ← shared/reusable UI components
├── ViewModels/             ← one VM per major view
├── Services/               ← business logic, API, HealthKit, etc.
├── Utils/                  ← extensions, helpers, constants
└── Resources/              ← assets, colors, fonts (if any)
```

**Steps:**
1. Create each folder as a **group with folder** in Xcode (not just a virtual group — actual directories on disk)
2. Move `GHISAApp.swift` into `App/`
3. Delete `ContentView.swift` (it will be replaced by the tab navigation shell)
4. Move `Assets.xcassets` into `Resources/`
5. Keep `Preview Content/` at the root of the target (Xcode expects it there)

**Acceptance criteria:**
- [ ] Every folder exists on disk under `ios/GHISA/`
- [ ] `GHISAApp.swift` is in `App/`
- [ ] `Assets.xcassets` is in `Resources/`
- [ ] No orphaned files at the target root except `Preview Content/` and `Info.plist`
- [ ] Project still builds and runs

---

### 1.3 App Constants & Configuration

**Goal:** Centralize the app name, API URLs, and other constants so nothing is hardcoded in views.

**File: `App/Config.swift`**

```swift
import Foundation

enum AppConfig {
    static let appName = "GHISA"

    enum API {
        #if DEBUG
        static let baseURL = URL(string: "http://localhost:8000/api/v1")!
        #else
        static let baseURL = URL(string: "https://api.ghisa.app/api/v1")!
        #endif
    }

    enum HealthKit {
        /// Number of days to import on first HealthKit authorization
        static let historicalImportDays = 90
    }

    enum Correlation {
        /// Minimum matched data points for a correlation to be computed
        static let minimumSampleSize = 20
        /// Significance threshold (after BH correction)
        static let significanceThreshold: Double = 0.05
        /// Maximum lag days to test
        static let maximumLagDays = 7
    }

    enum Defaults {
        static let defaultUnitSystem = "metric"
        static let defaultMealCategories = ["Breakfast", "Lunch", "Dinner", "Snack"]
    }
}
```

**Acceptance criteria:**
- [ ] `AppConfig.appName` is used wherever the app name appears (not string literals)
- [ ] API base URL switches between debug and release
- [ ] All magic numbers from PRD/CORRELATION_ENGINE.md are captured here

---

### 1.4 App Error Enum

**File: `Utils/AppError.swift`**

Per CLAUDE.md, define a shared error type for the entire app.

```swift
import Foundation

enum AppError: LocalizedError {
    case network(underlying: Error)
    case database(underlying: Error)
    case healthKit(underlying: Error)
    case validation(message: String)
    case sync(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .network: return "A network error occurred. Please try again."
        case .database: return "A data error occurred. Please try again."
        case .healthKit: return "Could not access health data."
        case .validation(let message): return message
        case .sync: return "Sync failed. Your data is safe locally."
        }
    }
}
```

**Acceptance criteria:**
- [ ] All five cases from CLAUDE.md are present
- [ ] `errorDescription` returns user-friendly strings (never raw error messages)
- [ ] File compiles

---

## Phase 2: Theming & Design Tokens

### 2.1 Color Extension

**File: `Utils/Color+Hex.swift`**

A `Color` initializer from hex strings, used by the theme.

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        // Parse hex string (with or without #) into RGB components
        // Handle 6-char (RGB) and 8-char (ARGB) hex strings
    }
}
```

**Acceptance criteria:**
- [ ] `Color(hex: "#0A84FF")` produces the correct blue
- [ ] Handles both `#RRGGBB` and `RRGGBB` formats
- [ ] Handles `#RRGGBBAA` for colors with alpha

---

### 2.2 Theme Definition

**File: `Utils/Theme.swift`**

Centralizes every visual token from `STYLE_GUIDE.md`. Views reference `Theme.x` — never raw hex values.

```swift
import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    enum Background {
        static let base = Color(hex: "#000000")
        static let surface = Color(hex: "#1C1C1E")
        static let elevated = Color(hex: "#2C2C2E")
        static let divider = Color(hex: "#38383A")
    }

    // MARK: - Accent
    enum Accent {
        static let primary = Color(hex: "#0A84FF")
        static let primaryDimmed = Color(hex: "#0A84FF").opacity(0.15)
    }

    // MARK: - Text
    enum Text {
        static let primary = Color.white
        static let secondary = Color(hex: "#ABABAB")
        static let tertiary = Color(hex: "#636366")
    }

    // MARK: - Semantic
    enum Semantic {
        static let success = Color(hex: "#30D158")
        static let warning = Color(hex: "#FFD60A")
        static let error = Color(hex: "#FF453A")
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum Radius {
        static let card: CGFloat = 12
        static let button: CGFloat = 12
        static let input: CGFloat = 10
        static let barCorner: CGFloat = 4
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold)
        static let sectionHeader = Font.system(size: 20, weight: .semibold)
        static let cardTitle = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let callout = Font.system(size: 14, weight: .medium)
        static let caption = Font.system(size: 12, weight: .regular)
        static let metricValue = Font.system(size: 34, weight: .bold).monospacedDigit()
        static let metricUnit = Font.system(size: 15, weight: .regular)
    }

    // MARK: - Animation
    enum Animation {
        static let cardExpansion = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let contentAppear = SwiftUI.Animation.easeOut(duration: 0.25)
        static let chartInteraction = SwiftUI.Animation.easeOut(duration: 0.2)
    }

    // MARK: - Component Sizes
    enum Size {
        static let buttonMinHeight: CGFloat = 48
        static let tabBarIconWeight: Font.Weight = .medium
    }
}
```

**Acceptance criteria:**
- [ ] Every color from STYLE_GUIDE.md is present
- [ ] Every spacing token is present
- [ ] Every typography style is present
- [ ] No raw hex values or magic numbers exist in any view — all go through `Theme`

---

### 2.3 Reusable Card Component

**File: `Views/Components/CardView.swift`**

A styled container matching the card spec from the style guide.

```swift
import SwiftUI

struct CardView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Theme.Spacing.lg)
            .background(Theme.Background.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
```

**Acceptance criteria:**
- [ ] Uses `Theme` tokens for background, padding, corner radius
- [ ] No shadows (per style guide — rely on background contrast)
- [ ] Accepts arbitrary content via `@ViewBuilder`

---

## Phase 3: Tab Navigation Shell

### 3.1 Main Tab View

**Goal:** The app's root view — 3 bottom tabs + profile icon in top-right. Each tab shows a placeholder for now.

**File: `App/MainTabView.swift`**

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .insights
    @State private var showingProfile = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Insights", systemImage: "chart.line.uptrend.xyaxis", value: .insights) {
                NavigationStack {
                    InsightsPlaceholderView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                        }
                }
            }

            Tab("Train", systemImage: "dumbbell", value: .train) {
                NavigationStack {
                    TrainingPlaceholderView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                        }
                }
            }

            Tab("Daily Log", systemImage: "calendar", value: .dailyLog) {
                NavigationStack {
                    DailyLogPlaceholderView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                        }
                }
            }
        }
        .tint(Theme.Accent.primary)
        .sheet(isPresented: $showingProfile) {
            ProfilePlaceholderView()
        }
    }

    private var profileButton: some View {
        Button {
            showingProfile = true
        } label: {
            Image(systemName: "person.circle")
                .font(.title3)
                .foregroundStyle(Theme.Text.secondary)
        }
    }
}

enum AppTab: Hashable {
    case insights
    case train
    case dailyLog
}
```

**Acceptance criteria:**
- [ ] 3 tabs visible at bottom: Insights, Train, Daily Log
- [ ] Tab icons use SF Symbols: `chart.line.uptrend.xyaxis`, `dumbbell`, `calendar`
- [ ] Active tab is accent blue, inactive is tertiary gray
- [ ] Profile icon (top-right) is visible on every tab
- [ ] Tapping profile icon opens a sheet
- [ ] Tab bar background is black (`#000000`)
- [ ] Each tab wraps content in `NavigationStack`
- [ ] Insights is the default/selected tab on launch

---

### 3.2 Placeholder Views

**Goal:** One placeholder per tab + profile, so the app is navigable end-to-end.

**Files:**
- `Views/Insights/InsightsPlaceholderView.swift`
- `Views/Training/TrainingPlaceholderView.swift`
- `Views/DailyLog/DailyLogPlaceholderView.swift`
- `Views/Profile/ProfilePlaceholderView.swift`

Each placeholder follows this pattern:

```swift
import SwiftUI

struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.Background.base.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Text.tertiary)
                Text("Insights")
                    .font(Theme.Typography.sectionHeader)
                    .foregroundStyle(Theme.Text.primary)
                Text("Coming soon")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.tertiary)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

Repeat the same pattern for Training (`dumbbell`), Daily Log (`calendar`), and Profile (`person.circle`).

**Acceptance criteria:**
- [ ] Each placeholder has the correct icon, title, and "Coming soon" label
- [ ] All use `Theme` colors — no hardcoded values
- [ ] Background is `Theme.Background.base`
- [ ] Navigation title is inline style (`.navigationBarTitleDisplayMode(.inline)`)
- [ ] Profile placeholder works inside a sheet

---

### 3.3 Update App Entry Point

**File: `App/GHISAApp.swift`**

Wire up `MainTabView` as the root and configure the SwiftData model container.

```swift
import SwiftUI
import SwiftData

@main
struct GHISAApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)  // dark theme only, per style guide
        }
        .modelContainer(for: [
            // All SwiftData models listed here — populated in Phase 4
        ])
    }
}
```

**Acceptance criteria:**
- [ ] App launches to `MainTabView`
- [ ] Color scheme is forced to `.dark`
- [ ] SwiftData `modelContainer` is configured (empty model list is fine until Phase 4)
- [ ] No crashes on launch

---

## Phase 4: SwiftData Models

### 4.1 Overview

Translate every table from `DATA_MODEL.md` into a SwiftData `@Model` class. One file per model, all in `Models/`.

**File naming:** Match the entity name in singular PascalCase: `User.swift`, `Exercise.swift`, `Workout.swift`, etc.

**Conventions for all models:**
- Use `@Model` macro
- Use `UUID()` default for `id`
- Use `Date()` default for `created_at` / `updated_at`
- Use Swift-native types (`String`, `Int`, `Double`, `Bool`, `Date`, `[String]`)
- Use `@Relationship` for all associations, with appropriate `deleteRule`
- Store all measurements in **metric** (conversion happens in views)
- Add SwiftData `#Index` macros for the indexes listed in DATA_MODEL.md

### 4.2 Model List

Create one file per model, in this order (respecting dependencies — a model can only reference models defined before it or in the same pass):

| # | File | Model Class | DATA_MODEL.md Table | Key Notes |
|---|------|------------|---------------------|-----------|
| 1 | `Models/User.swift` | `User` | `users` | Single user for V1. All other models reference this. |
| 2 | `Models/Exercise.swift` | `Exercise` | `exercises` | `muscle_groups` is `[String]`. `is_archived` for soft delete. |
| 3 | `Models/ExerciseFieldDefinition.swift` | `ExerciseFieldDefinition` | `exercise_field_definitions` | `system_key` identifies reps/weight/rpe/rest/tempo. `select_options` is `[String]?`. |
| 4 | `Models/Workout.swift` | `Workout` | `workouts` | `status` is `String` ("in_progress"/"completed"/"discarded"). |
| 5 | `Models/WorkoutExercise.swift` | `WorkoutExercise` | `workout_exercises` | Join between workout and exercise with sort order. |
| 6 | `Models/WorkoutSet.swift` | `WorkoutSet` | `workout_sets` | Container for set values. `set_number` for ordering. |
| 7 | `Models/WorkoutSetValue.swift` | `WorkoutSetValue` | `workout_set_values` | Polymorphic value: `value_number`, `value_text`, `value_toggle`. One row per field per set. |
| 8 | `Models/WorkoutTemplate.swift` | `WorkoutTemplate` | `workout_templates` | Reusable workout structures. |
| 9 | `Models/WorkoutTemplateExercise.swift` | `WorkoutTemplateExercise` | `workout_template_exercises` | Exercise within a template. |
| 10 | `Models/WorkoutTemplateFieldTarget.swift` | `WorkoutTemplateFieldTarget` | `workout_template_field_targets` | Target values within a template. |
| 11 | `Models/Flag.swift` | `Flag` | `flags` | `scope` is "workout"/"exercise"/"set". |
| 12 | `Models/FlagAssignment.swift` | `FlagAssignment` | `flag_assignments` | Polymorphic FK: exactly one of `workout`/`workoutExercise`/`workoutSet` is non-nil. |
| 13 | `Models/NutrientDefinition.swift` | `NutrientDefinition` | `nutrient_definitions` | User-customizable nutrients. Seeded with defaults. |
| 14 | `Models/FoodItem.swift` | `FoodItem` | `food_items` | Cached from API or user-created. `user_id` null = from API. |
| 15 | `Models/FoodItemNutrient.swift` | `FoodItemNutrient` | `food_item_nutrients` | Per-food per-nutrient values. |
| 16 | `Models/Recipe.swift` | `Recipe` | `recipes` | User-created food combinations. |
| 17 | `Models/RecipeIngredient.swift` | `RecipeIngredient` | `recipe_ingredients` | Food items within a recipe. |
| 18 | `Models/MealCategory.swift` | `MealCategory` | `meal_categories` | User-defined meal slots. Seeded with defaults. |
| 19 | `Models/MealEntry.swift` | `MealEntry` | `meal_entries` | Individual food log entry. Polymorphic: `foodItem` or `recipe`. |
| 20 | `Models/MealTemplate.swift` | `MealTemplate` | `meal_templates` | Reusable meal combinations. |
| 21 | `Models/MealTemplateItem.swift` | `MealTemplateItem` | `meal_template_items` | Items within a meal template. Polymorphic: `foodItem` or `recipe`. |
| 22 | `Models/NutritionTarget.swift` | `NutritionTarget` | `nutrition_targets` | User's daily goals per nutrient. |
| 23 | `Models/DailyLog.swift` | `DailyLog` | `daily_logs` | One per user per day. HealthKit columns hardcoded. |
| 24 | `Models/DailyLogFieldDefinition.swift` | `DailyLogFieldDefinition` | `daily_log_field_definitions` | User-defined daily tracking fields. |
| 25 | `Models/DailyLogValue.swift` | `DailyLogValue` | `daily_log_values` | Per-field per-day values. |
| 26 | `Models/CorrelationResult.swift` | `CorrelationResult` | `correlation_results` | Cached pre-computed correlations. |

### 4.3 Model Implementation Details

#### Relationship delete rules

| Parent | Child | Delete Rule |
|--------|-------|-------------|
| `User` | `Exercise`, `Workout`, `Flag`, etc. | `.cascade` |
| `Exercise` | `ExerciseFieldDefinition` | `.cascade` |
| `Exercise` | `WorkoutExercise` | `.nullify` (preserve history if exercise is deleted — though we use soft-delete via `is_archived`) |
| `Workout` | `WorkoutExercise` | `.cascade` |
| `WorkoutExercise` | `WorkoutSet` | `.cascade` |
| `WorkoutSet` | `WorkoutSetValue` | `.cascade` |
| `WorkoutTemplate` | `WorkoutTemplateExercise` | `.cascade` |
| `WorkoutTemplateExercise` | `WorkoutTemplateFieldTarget` | `.cascade` |
| `Flag` | `FlagAssignment` | `.cascade` |
| `FoodItem` | `FoodItemNutrient` | `.cascade` |
| `Recipe` | `RecipeIngredient` | `.cascade` |
| `MealTemplate` | `MealTemplateItem` | `.cascade` |
| `DailyLog` | `DailyLogValue` | `.cascade` |
| `NutrientDefinition` | `FoodItemNutrient`, `NutritionTarget` | `.cascade` |
| `MealCategory` | `MealEntry` | `.nullify` |

#### Example model (reference pattern)

```swift
// Models/Exercise.swift
import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var user: User
    var name: String
    var muscleGroups: [String]
    var movementType: String?
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \ExerciseFieldDefinition.exercise)
    var fieldDefinitions: [ExerciseFieldDefinition]

    var createdAt: Date
    var updatedAt: Date

    init(
        user: User,
        name: String,
        muscleGroups: [String] = [],
        movementType: String? = nil
    ) {
        self.id = UUID()
        self.user = user
        self.name = name
        self.muscleGroups = muscleGroups
        self.movementType = movementType
        self.isArchived = false
        self.fieldDefinitions = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

Follow this pattern for all 26 models. Use `camelCase` property names (Swift convention), not `snake_case` (which is the DB convention).

### 4.4 Register Models in App Entry Point

Once all models are created, register them in `GHISAApp.swift`:

```swift
.modelContainer(for: [
    User.self,
    Exercise.self,
    ExerciseFieldDefinition.self,
    Workout.self,
    WorkoutExercise.self,
    WorkoutSet.self,
    WorkoutSetValue.self,
    WorkoutTemplate.self,
    WorkoutTemplateExercise.self,
    WorkoutTemplateFieldTarget.self,
    Flag.self,
    FlagAssignment.self,
    NutrientDefinition.self,
    FoodItem.self,
    FoodItemNutrient.self,
    Recipe.self,
    RecipeIngredient.self,
    MealCategory.self,
    MealEntry.self,
    MealTemplate.self,
    MealTemplateItem.self,
    NutritionTarget.self,
    DailyLog.self,
    DailyLogFieldDefinition.self,
    DailyLogValue.self,
    CorrelationResult.self,
])
```

### 4.5 Data Seeding Service

**File: `Services/DataSeedService.swift`**

On first launch, seed default data that the app expects to exist:

**What to seed:**
1. A default `User` (V1 is single-user, no auth)
2. Default `MealCategory` entries: Breakfast (sort 0), Lunch (sort 1), Dinner (sort 2), Snack (sort 3) — all with `isDefault = true`
3. Default `NutrientDefinition` entries:
   - Calories (kcal, `apiKey: "energy-kcal"`, sort 0)
   - Protein (g, `apiKey: "proteins"`, sort 1)
   - Carbs (g, `apiKey: "carbohydrates"`, sort 2)
   - Fat (g, `apiKey: "fat"`, sort 3)
   - All with `isDefault = true`, `isVisible = true`
4. Default `DailyLogFieldDefinition`: Body Weight (number, kg, `systemKey: "body_weight"`, `isDefault = true`)

**Logic:**
- Check if a `User` exists in the database. If yes, skip seeding entirely.
- If no user exists, create all defaults in a single transaction.
- Call this from `GHISAApp.swift` on app launch.

**Acceptance criteria:**
- [ ] First launch creates the default user and all seed data
- [ ] Second launch does not duplicate seed data
- [ ] All seed data matches what DATA_MODEL.md specifies
- [ ] Meal categories are in the correct sort order
- [ ] Nutrient definitions have correct `apiKey` values

---

## Phase 5: Core Service Stubs

### 5.1 HealthKit Service

**File: `Services/HealthKitService.swift`**

A stub that establishes the interface. No real HealthKit calls yet — just the method signatures and permission request flow.

**Interface:**

```swift
import HealthKit

@Observable
final class HealthKitService {
    private let healthStore = HKHealthStore()

    var isAuthorized = false

    /// Types we want to read from HealthKit
    private var readTypes: Set<HKObjectType> {
        // sleepAnalysis, stepCount, restingHeartRate, heartRateVariabilitySDNN,
        // activeEnergyBurned, distanceWalkingRunning, bodyMass
    }

    /// Request HealthKit authorization
    func requestAuthorization() async throws { }

    /// Fetch data for a specific date range and populate DailyLog entries
    func fetchData(from startDate: Date, to endDate: Date) async throws { }

    /// Fetch historical data (90 days) — called once on first authorization
    func performHistoricalImport() async throws { }
}
```

**Acceptance criteria:**
- [ ] File compiles
- [ ] All HealthKit types from PRD section 4.2 are listed
- [ ] Method signatures match the expected usage pattern
- [ ] No actual HealthKit calls (stub only — methods can be empty or throw "not implemented")

---

### 5.2 API Client

**File: `Services/APIClient.swift`**

Stub for backend communication. V1 is local-only, so this is purely structural.

**Interface:**

```swift
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
    ) async throws -> T { }

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
```

**Acceptance criteria:**
- [ ] File compiles
- [ ] Response envelope matches CLAUDE.md API response format
- [ ] Uses `AppConfig.API.baseURL`
- [ ] All methods throw `AppError.network` on failure

---

### 5.3 Correlation Engine

**File: `Services/CorrelationEngine.swift`**

Stub with the computation interface. No statistical logic yet.

**Interface:**

```swift
import Foundation
import Accelerate

@Observable
final class CorrelationEngine {
    /// Run full recomputation of all correlations
    func recomputeAll(for userId: UUID) async throws { }

    /// Incremental update — only recompute targets/factors with new data
    func incrementalUpdate(for userId: UUID, since lastComputation: Date) async throws { }

    /// Get all significant correlations for a target variable
    func significantFactors(for target: String, userId: UUID) -> [CorrelationResult] { }

    /// Compute partial correlations for "What Matters Most" ranking
    func partialCorrelations(for target: String, userId: UUID) async throws -> [CorrelationResult] { }
}
```

**Acceptance criteria:**
- [ ] File compiles
- [ ] `import Accelerate` is present (will be used for vector math later)
- [ ] Method signatures align with CORRELATION_ENGINE.md sections 7 and 8

---

### 5.4 Sync Service

**File: `Services/SyncService.swift`**

V1 stub — no sync functionality. Just the interface for V2.

```swift
import Foundation

@Observable
final class SyncService {
    var isSyncing = false
    var lastSyncDate: Date?

    /// V1: no-op. V2: sync local changes to backend.
    func syncIfNeeded() async { }
}
```

**Acceptance criteria:**
- [ ] File compiles
- [ ] Does nothing in V1 (empty method bodies)

---

## Phase 6: Exercise Default Seeding Logic

### 6.1 Exercise Field Seeding

**File: `Services/ExerciseService.swift`**

When a new exercise is created, automatically seed its default field definitions. This is not first-launch seeding — it happens every time the user creates a new exercise.

**Default fields to seed per new exercise:**

| Name | Field Type | Unit | System Key | Sort Order | Is Default |
|------|-----------|------|------------|------------|------------|
| Reps | number | null | "reps" | 0 | true |
| Weight | number | "kg" | "weight" | 1 | true |
| RPE | number | null | "rpe" | 2 | true |
| Rest | number | "seconds" | "rest" | 3 | true |
| Tempo | text | null | "tempo" | 4 | true |

**Interface:**

```swift
@Observable
final class ExerciseService {
    private let modelContext: ModelContext

    /// Create a new exercise with default field definitions
    func createExercise(
        user: User,
        name: String,
        muscleGroups: [String],
        movementType: String?
    ) throws -> Exercise { }

    /// Add a custom field definition to an exercise
    func addCustomField(
        to exercise: Exercise,
        name: String,
        fieldType: String,
        unit: String?,
        selectOptions: [String]?
    ) throws -> ExerciseFieldDefinition { }
}
```

**Acceptance criteria:**
- [ ] Creating an exercise auto-creates 5 default field definitions
- [ ] Default fields have correct `systemKey` values
- [ ] Default fields have `isDefault = true`
- [ ] User-created custom fields have `systemKey = nil` and `isDefault = false`

---

## Phase 7: Backend Scaffold (Deferrable)

> **Note:** V1 is local-only per the PRD. This phase can be deferred entirely until backend work begins. It's included here so the structure is ready.

### 7.1 Initialize Node.js Project

```bash
cd backend
npm init -y
```

Update `package.json` with:
- `"name": "ghisa-backend"`
- `"type": "module"` (ES modules)
- Scripts:
  - `"dev": "tsx watch src/index.ts"`
  - `"build": "tsc"`
  - `"start": "node dist/index.js"`
  - `"test": "jest --passWithNoTests"`
  - `"lint": "eslint src/"`
  - `"format": "prettier --write src/"`

### 7.2 Install Dependencies

**Production:**
```bash
npm install express cors helmet dotenv jsonwebtoken bcryptjs zod @prisma/client
```

**Development:**
```bash
npm install -D typescript @types/node @types/express @types/cors @types/jsonwebtoken @types/bcryptjs tsx prisma jest @types/jest ts-jest supertest @types/supertest @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-prettier
```

### 7.3 TypeScript Configuration

**File: `backend/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### 7.4 Express App Entry Point

**File: `backend/src/index.ts`**

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { errorHandler } from './middleware/errorHandler.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT ?? 8000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/api/v1/health', (_req, res) => {
  res.json({ success: true, data: { status: 'ok', timestamp: new Date().toISOString() } });
});

// Error handler (must be last)
app.use(errorHandler);

app.listen(PORT, () => {
  console.warn(`Server running on port ${PORT}`);
});

export default app;
```

### 7.5 Error Handling Middleware

**File: `backend/src/middleware/errorHandler.ts`**

```typescript
import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(404, 'NOT_FOUND', message);
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super(400, 'VALIDATION_ERROR', message);
  }
}

export class AuthError extends AppError {
  constructor(message = 'Unauthorized') {
    super(401, 'AUTH_ERROR', message);
  }
}

export class DatabaseError extends AppError {
  constructor(message = 'Database error') {
    super(500, 'DATABASE_ERROR', message);
  }
}

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      error: { code: err.code, message: err.message },
    });
    return;
  }

  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' },
  });
}
```

### 7.6 Prisma Schema

**File: `backend/prisma/schema.prisma`**

Initialize Prisma and translate `DATA_MODEL.md` tables into Prisma models. This mirrors the SwiftData models but for PostgreSQL.

```bash
cd backend
npx prisma init
```

Then populate `schema.prisma` with all models from DATA_MODEL.md, using:
- `uuid` for IDs with `@default(uuid())`
- `@relation` for all foreign keys
- `@@index` for the indexes listed in DATA_MODEL.md
- `@@unique` for unique constraints (e.g., `daily_logs(user_id, date)`)
- `snake_case` table and column names (via `@@map` and `@map`)

### 7.7 Environment File Template

**File: `backend/.env.example`**

```env
DATABASE_URL=postgresql://user:password@localhost:5432/ghisa
JWT_SECRET=change-me-to-a-random-256-bit-secret
JWT_EXPIRES_IN=7d
PORT=8000
NODE_ENV=development
FOOD_API_KEY=your-api-key-here
```

### 7.8 Backend Acceptance Criteria

- [ ] `npm install` succeeds with no errors
- [ ] `npm run dev` starts the server on port 8000
- [ ] `GET /api/v1/health` returns `{ success: true, data: { status: "ok" } }`
- [ ] `npm test` passes (with `--passWithNoTests`)
- [ ] `npm run lint` passes
- [ ] TypeScript compiles with zero errors (`npx tsc --noEmit`)
- [ ] `.env.example` exists but `.env` is gitignored
- [ ] Prisma schema is valid (`npx prisma validate`)

---

## Phase 8: Unit Test Targets

### 8.1 iOS Test Target

**Steps:**
1. In Xcode, add a new target: **Unit Testing Bundle**
   - Product Name: `GHISATests`
   - Target to be Tested: `GHISA`
   - Location: `ios/GHISATests/`
2. Create the test directory structure:
   ```
   ios/GHISATests/
   ├── Models/          ← tests for model computed properties, validation
   ├── ViewModels/      ← tests for view model logic, state changes
   └── Services/        ← tests for service business logic
   ```
3. Add a simple smoke test to verify the setup works:

**File: `ios/GHISATests/SmokeTest.swift`**

```swift
import Testing
@testable import GHISA

struct SmokeTest {
    @Test func appConfigExists() {
        #expect(AppConfig.appName == "GHISA")
        #expect(AppConfig.Correlation.minimumSampleSize == 20)
    }
}
```

### 8.2 Backend Test Setup

**File: `backend/jest.config.ts`**

```typescript
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js', 'json'],
};

export default config;
```

**File: `backend/tests/health.test.ts`**

```typescript
import request from 'supertest';
import app from '../src/index.js';

describe('GET /api/v1/health', () => {
  it('returns success', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('ok');
  });
});
```

### 8.3 Acceptance Criteria

- [ ] iOS: `⌘U` runs the smoke test and it passes
- [ ] Backend: `npm test` runs the health check test and it passes

---

## Phase 9: Final Verification Checklist

Before starting any feature development, verify all of the following:

### Build & Run
- [ ] `xcodebuild -project ios/GHISA.xcodeproj -scheme GHISA -destination 'platform=iOS Simulator,name=iPhone 16' build` succeeds
- [ ] App launches on simulator with 3-tab navigation
- [ ] Each tab is tappable and shows its placeholder
- [ ] Profile button opens a sheet from any tab
- [ ] App is dark-themed (forced `.dark` color scheme)

### Project Structure
- [ ] All folders from CLAUDE.md section "Project Structure" exist on disk
- [ ] No files are at wrong locations (e.g., no Swift files at the target root)

### Models
- [ ] All 26 SwiftData models compile
- [ ] All models are registered in the `modelContainer`
- [ ] App launches without SwiftData migration errors
- [ ] First launch seeds: 1 user, 4 meal categories, 4 nutrient definitions, 1 daily log field definition

### Theming
- [ ] `Theme.swift` has all colors, spacing, typography, and animation tokens from STYLE_GUIDE.md
- [ ] All placeholder views use `Theme` values (no hardcoded colors, sizes, or fonts)

### Services
- [ ] All 5 service files compile: `DataSeedService`, `HealthKitService`, `APIClient`, `CorrelationEngine`, `SyncService`, `ExerciseService`
- [ ] No runtime crashes from stub methods

### Tests
- [ ] iOS smoke test passes
- [ ] Backend health check test passes (if Phase 7 was completed)

### Code Quality
- [ ] Zero compiler warnings
- [ ] SwiftLint passes (if installed): `swiftlint lint --path ios/GHISA/`
- [ ] No `UIKit` imports anywhere
- [ ] No `Combine` imports anywhere
- [ ] No `ObservableObject` usage anywhere
- [ ] No hardcoded hex color values in views
- [ ] No hardcoded "GHISA" string in user-facing views (use `AppConfig.appName`)

### Git
- [ ] All new files are tracked
- [ ] `.gitignore` covers `xcuserdata/`, `DerivedData/`, `build/`, `.env`, `node_modules/`
- [ ] No secrets or `.env` files are committed

---

## Implementation Order Summary

| Order | Phase | Estimated Effort | Dependency |
|-------|-------|-----------------|------------|
| 1 | Phase 1: Xcode project + folder structure | Small | None |
| 2 | Phase 2: Theme + design tokens | Small | Phase 1 |
| 3 | Phase 3: Tab navigation shell | Small | Phase 1, 2 |
| 4 | Phase 4: SwiftData models (all 26) | Large | Phase 1 |
| 5 | Phase 6: Exercise seeding logic | Small | Phase 4 |
| 6 | Phase 5: Service stubs | Small | Phase 1, 4 |
| 7 | Phase 8: Test targets | Small | Phase 1, 5 |
| 8 | Phase 9: Final verification | Small | All above |
| — | Phase 7: Backend scaffold | Medium | None (independent, deferrable) |

After completing all phases, the project is ready for feature development. Start with the Training module (Model → Service → ViewModel → View) per CLAUDE.md guidance.
