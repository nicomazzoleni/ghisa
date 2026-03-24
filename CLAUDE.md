# GHISA — Project Instructions for Claude

## Project Overview

GHISA (working title) is a native iOS app that centralizes gym performance, nutrition, and lifestyle data with a correlation engine that reveals how different factors affect training performance.

**Owner:** Nico — moderate Python, advanced SQL, no prior iOS/Swift experience.
**Status:** Greenfield project, starting from scratch.

## Tech Stack

### iOS App
- **Language:** Swift 6
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData (local cache + offline support)
- **Minimum iOS:** 17.0
- **Architecture:** MVVM (Model–View–ViewModel)
- **Health Data:** HealthKit
- **Computation:** Accelerate framework (correlations, statistics)
- **Charts:** Swift Charts
- **Target:** iPhone only (no iPad/Watch for V1)

### Backend
- **Language:** TypeScript (Node.js)
- **Framework:** Express.js
- **Database:** PostgreSQL
- **ORM:** Prisma
- **Validation:** Zod
- **Auth:** JWT tokens + Apple Sign-In
- **API Style:** RESTful, versioned (e.g., /api/v1/)

## Project Structure

```
GHISA/
├── CLAUDE.md              ← you are here
├── docs/
│   ├── PRD.md             ← product requirements (source of truth for features)
│   ├── DATA_MODEL.md      ← database schema
│   └── CORRELATION_ENGINE.md ← statistical methodology for the insights engine
├── ios/GHISA/
│   ├── App/               ← app entry point, app-level config
│   ├── Models/            ← SwiftData models
│   ├── Views/
│   │   ├── Insights/      ← home tab — correlation dashboard
│   │   ├── Training/      ← workout logging
│   │   ├── DailyLog/      ← nutrition + lifestyle combined
│   │   ├── Profile/       ← profile sheet (top-right icon)
│   │   └── Components/    ← shared/reusable UI components
│   ├── ViewModels/        ← one VM per major view
│   ├── Services/
│   │   ├── APIClient.swift       ← backend communication
│   │   ├── HealthKitService.swift ← HealthKit read/write
│   │   ├── CorrelationEngine.swift ← statistical computation
│   │   └── SyncService.swift      ← local ↔ server sync
│   ├── Utils/             ← extensions, helpers, constants
│   └── Resources/         ← assets, colors, fonts
├── backend/
│   ├── src/
│   │   ├── index.ts       ← Express app entry point
│   │   ├── routes/        ← endpoint groups
│   │   ├── middleware/     ← auth, validation, error handling
│   │   ├── services/      ← business logic
│   │   └── utils/         ← helpers
│   ├── prisma/
│   │   └── schema.prisma  ← database schema + models
│   ├── tests/
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
└── .gitignore
```

## Code Conventions

### Swift / iOS
- Use SwiftUI declarative syntax, never UIKit
- Follow Apple's Swift API Design Guidelines (camelCase, descriptive names)
- Use `@Observable` (Observation framework) for view models, not `ObservableObject`
- Use SwiftData `@Model` for all persistent entities
- Use `async/await` for all asynchronous work — no Combine unless absolutely necessary
- Keep views small: extract subviews into separate files when a view exceeds ~80 lines
- Use Swift's native error handling (`do/catch`, `Result`)
- File naming: `ExerciseDetailView.swift`, `WorkoutViewModel.swift`, `HealthKitService.swift`

### TypeScript / Backend
- Strict TypeScript (`strict: true` in tsconfig)
- Use Zod schemas for all request validation
- Use Prisma for all database access — no raw SQL unless necessary
- Use `async/await` for all async operations
- File naming: camelCase (`workoutRouter.ts`, `mealService.ts`)
- Tests in `backend/tests/`, use Jest + Supertest for API tests
- Use ESLint + Prettier for formatting

### SQL
- Table names: snake_case, plural (e.g., `workout_sets`, `meal_entries`)
- Column names: snake_case
- Always use foreign keys with ON DELETE CASCADE where appropriate
- Index frequently queried columns (user_id, date, exercise_id)

## Navigation Structure

3 bottom tabs + profile icon (top-right):
1. **Insights** (home/landing) — correlation dashboard
2. **Train** — workout logging
3. **Daily Log** — nutrition + lifestyle combined

Profile: accessible via top-right icon on any screen (opens as a sheet).

## Key Features Reference

Refer to `docs/PRD.md` for full details. Summary:

- **Training:** freeform "paper notebook" logging with custom exercises, custom fields (number/text/dropdown/toggle), and a multi-scope flag system (workout/exercise/set level)
- **Nutrition:** food database + barcode scanning, macros + key micros, recipes, meal templates
- **Lifestyle:** HealthKit auto-pull + manual subjective ratings (stress, energy, mood, soreness)
- **Correlation Engine:** significance-gated analysis — only statistically significant correlations (BH-adjusted p < 0.05, n ≥ 20) are surfaced. Uses Spearman for continuous, Mann-Whitney for binary, Kruskal-Wallis for categorical factors. Pre-built insight cards + guided Explore flow + "Only when..." filters + "What Matters Most" partial correlation summary. All stats hidden from user — plain language only. Full methodology in `docs/CORRELATION_ENGINE.md`.

## Build & Run

### iOS
```bash
# Open in Xcode
open ios/GHISA.xcodeproj

# Build from command line
xcodebuild -project ios/GHISA.xcodeproj -scheme GHISA -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project ios/GHISA.xcodeproj -scheme GHISA -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### Backend
```bash
cd backend

# Setup
npm install

# Run dev server
npm run dev    # runs ts-node-dev with auto-reload on port 8000

# Database
npx prisma generate       # generate Prisma client after schema changes
npx prisma migrate dev    # create + apply migration
npx prisma studio         # visual DB browser

# Run tests
npm test
```

## Important Constraints

- **Offline-first:** the iOS app must work fully without internet. All data is stored locally via SwiftData. Sync to backend happens in the background when online.
- **HealthKit data stays on device:** Apple requires that HealthKit data is not uploaded to external servers. Use it only for on-device correlations.
- **No statistical jargon in UI:** the user never sees p-values, r-values, or confidence intervals. Use plain language badges and color coding.
- **Significance gating:** never show a correlation or analysis option to the user unless it is statistically significant (p < 0.05, n ≥ 20).
- **Working title:** "GHISA" is a working title. Keep naming flexible for an easy rename later (avoid hardcoding the name in too many places).

## Error Handling

### Swift / iOS
- Use Swift's `do/catch` with typed errors. Define a shared `AppError` enum in `Utils/AppError.swift`:
  - `.network(underlying: Error)` — API call failures
  - `.database(underlying: Error)` — SwiftData errors
  - `.healthKit(underlying: Error)` — HealthKit access issues
  - `.validation(message: String)` — invalid user input
  - `.sync(underlying: Error)` — sync failures
- Views should show user-friendly error messages via alerts or inline banners — never expose raw error messages
- Network errors should be silent when offline (expected behavior) — queue for retry
- Log errors to console in debug builds only

### TypeScript / Backend
- Use a centralized error-handling middleware in `middleware/errorHandler.ts`
- Define custom error classes extending `Error`: `NotFoundError`, `ValidationError`, `AuthError`, `DatabaseError`
- All errors return the standard API response format (see below)
- Never expose stack traces or internal details in production responses
- Log all errors with context (route, user ID, request body)

## API Response Format

All backend endpoints return this consistent envelope:

```json
// Success
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "totalPages": 5, "totalCount": 48 }
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Weight must be a positive number"
  }
}
```

- Pagination: use `?page=1&limit=20` query params; default limit = 20, max = 100
- Dates: always ISO 8601 format (`2026-03-18T14:30:00Z`)
- IDs: UUIDs (not auto-increment integers) for all entities

## Environment Variables

### Backend (`backend/.env`)
```
DATABASE_URL=postgresql://user:password@localhost:5432/ghisa
JWT_SECRET=<random-256-bit-secret>
JWT_EXPIRES_IN=7d
PORT=8000
NODE_ENV=development
FOOD_API_KEY=<open-food-facts-or-usda-api-key>
```

### iOS
- API base URL configured in `App/Config.swift` with separate values for debug/release
- No secrets stored in the iOS app — all sensitive operations go through the backend
- HealthKit entitlements configured in Xcode project capabilities

**Never commit `.env` files.** Use `.env.example` with placeholder values.

## Git Workflow

- **Main branch:** `main` — always deployable
- **Feature branches:** `feature/<short-description>`
- **Bug fixes:** `fix/<short-description>`
- **Commit messages:** conventional commits format
- **No direct commits to `main`** — always work on a feature branch
- **Keep commits small and focused**

## Testing Strategy

### What to Test
- **Services (business logic):** high coverage
- **ViewModels:** test data flow, state changes, error handling
- **API routes:** test request validation, response format, auth, edge cases
- **Models:** test computed properties, validation rules
- **Views:** minimal testing

### Running Tests
- Run tests before committing to a feature branch
- All tests must pass before merging to `main`

## Approved Dependencies

### iOS — Apple built-in frameworks only
SwiftUI, SwiftData, HealthKit, Accelerate, Swift Charts

### Backend (npm)
express, prisma/@prisma/client, zod, jsonwebtoken, bcryptjs, cors, helmet, dotenv, tsx/ts-node-dev, jest/@types/jest, supertest, eslint+prettier

## Common Mistakes to Avoid

- **Never use UIKit** — SwiftUI only
- **Never use Combine** — use `async/await` and `@Observable`
- **Never use `ObservableObject`** — use `@Observable` macro (iOS 17+)
- **Never show raw error messages to users**
- **Never hardcode "GHISA"** in user-facing strings — use a constant
- **Never upload HealthKit data to the backend**
- **Never show statistical jargon** in the UI
- **Never surface an insignificant correlation**
- **Never use `any` type in TypeScript**
- **Never write raw SQL** — use Prisma

## Project Status

| Module | Status | Notes |
|--------|--------|-------|
| Project setup | In progress | Docs complete, code scaffold not started |
| Data model | Not started | SwiftData models + Prisma schema |
| Training — exercise CRUD | Not started | |
| Training — workout logging | Not started | |
| Training — flags system | Not started | |
| Training — history & PRs | Not started | |
| Nutrition — food database | Not started | |
| Nutrition — meal logging | Not started | |
| Nutrition — recipes | Not started | |
| Lifestyle — HealthKit | Not started | |
| Lifestyle — manual entry | Not started | |
| Correlation engine | Not started | |
| Insights dashboard | Not started | |
| Auth + user profile | Not started | |
| Sync (local ↔ server) | Not started | |
| Barcode scanning | Not started | |

## When Starting a New Feature

1. Check `docs/PRD.md` for the feature requirements
2. Check `docs/DATA_MODEL.md` for the relevant data models
3. Implement in this order: Model → Service → ViewModel → View
4. Write tests for services and view models
5. Update the **Project Status** table above when done
