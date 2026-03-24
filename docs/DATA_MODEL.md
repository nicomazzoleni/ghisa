# GHISA — Data Model

All IDs are UUIDs. All timestamps are ISO 8601 with timezone. Tables use snake_case, plural names.
This schema covers the **SwiftData** (on-device iOS) data model for V1 (local-only, no backend).

> **V2 & future items** (auth, sync, body measurements, progress photos, subjective ratings) are preserved in [`docs/DATA_MODEL_V2.md`](./DATA_MODEL_V2.md).

## Conventions

### Unit Storage
All physical measurements are stored in **metric units** as the canonical source of truth, regardless of the user's display preference:
- Weight (body and barbell): **kg** — stored via `exercise_field_definitions` (unit = "kg"), `daily_log_field_definitions` (system_key = "body_weight")
- Height: **cm** — `users.height_cm`
- Distance: **km** — `daily_logs.walking_distance_km`
- Nutrition weights: **grams/mg/mcg** as labeled per column

The app converts to imperial for display when `users.unit_system = "imperial"`. Conversion happens at the view layer only — never stored in imperial. If a user switches unit systems, no data migration is needed.

---

## 1. User Profile

### `users`
Local user profile. V1 has no authentication — single user on device.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| name | String | nullable |
| age | Int | nullable |
| gender | String | nullable — free text with combobox |
| height_cm | Float | nullable |
| weight_kg | Float | nullable (starting weight) |
| unit_system | String | "metric" or "imperial", default "metric" |
| created_at | DateTime | |
| updated_at | DateTime | |

---

## 2. Training Module

### `exercises`
User-defined exercise library.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Bench Press", "Barbell Squat" |
| muscle_groups | String[] | array of muscle group names |
| movement_type | String | nullable — free text with combobox (e.g., "push", "pull", "Olympic lift", "mobility") |
| is_archived | Boolean | default false — soft delete |
| created_at | DateTime | |
| updated_at | DateTime | |

> **Combobox pattern:** `movement_type` and `muscle_groups` are free-text fields. The UI shows a combobox — the user can type anything, but also sees a dropdown of all distinct values they've previously entered for that field. This gives the freedom of a notebook with the convenience of autocomplete.

### `exercise_field_definitions`
Fields that can be tracked per set for a given exercise. Includes both system-seeded defaults and user-created fields.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| exercise_id | UUID | FK → exercises |
| name | String | e.g., "Reps", "Weight", "RPE", "Grip Width", "Distance" |
| field_type | String | "number" / "text" / "select" / "toggle" |
| unit | String | nullable — e.g., "kg", "cm", "seconds", "degrees" |
| select_options | String[] | nullable — options for "select" type (e.g., ["overhand", "underhand", "neutral"]) |
| system_key | String | nullable — identifies system-seeded fields for computation: "reps", "weight", "rpe", "rest", "tempo". Null for user-created fields |
| sort_order | Int | display order |
| is_active | Boolean | default true — hidden fields are inactive but data is preserved |
| is_default | Boolean | true for system-seeded fields — can be hidden but not deleted |
| created_at | DateTime | |

> On exercise creation, the app seeds default field definitions: Reps (number), Weight (number, kg), RPE (number), Rest (number, seconds), Tempo (text). These have `system_key` set so the app can identify them for 1RM calculations, volume math, PR detection, and correlation variables. The user can hide any default (e.g., hide RPE for exercises they don't rate) and add any custom field (e.g., "Distance" for cardio, "Duration" for planks, "Incline Angle" for adjustable bench). All fields — system and custom — go through the same data path.

### `workouts`
A single training session.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| status | String | "in_progress" / "completed" / "discarded" — default "in_progress" |
| date | Date | training date |
| started_at | DateTime | nullable — when session began |
| ended_at | DateTime | nullable — when session ended |
| duration_minutes | Int | nullable — auto-calculated or manual |
| notes | Text | nullable — general session notes |
| location | String | nullable |
| created_at | DateTime | |
| updated_at | DateTime | |

> Only workouts with `status = "completed"` are included in history, PRs, and correlation analysis. `in_progress` workouts are auto-saved drafts. `discarded` workouts are soft-deleted (not synced, excluded from everything).

### `workout_templates`
Reusable workout structures.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Push Day", "Upper Body A" |
| notes | Text | nullable |
| created_at | DateTime | |
| updated_at | DateTime | |

### `workout_template_exercises`
Exercises within a template.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| template_id | UUID | FK → workout_templates |
| exercise_id | UUID | FK → exercises |
| sort_order | Int | display order |
| superset_group | Int | nullable |
| target_sets | Int | nullable — suggested number of sets |
| notes | Text | nullable |

### `workout_template_field_targets`
Target values for fields within a template exercise.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| template_exercise_id | UUID | FK → workout_template_exercises |
| field_definition_id | UUID | FK → exercise_field_definitions |
| target_value_number | Float | nullable — target for number fields |
| target_value_text | String | nullable — target for text fields |

> Templates are independent of workout history. Creating a workout from a template copies the structure into a new workout — subsequent edits to the template do not affect past workouts. `target_sets` remains on the template exercise since it controls how many set rows to create, not a per-set field value.

### `workout_exercises`
An exercise performed within a workout (join table with ordering).

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| workout_id | UUID | FK → workouts |
| exercise_id | UUID | FK → exercises |
| sort_order | Int | display order in workout |
| superset_group | Int | nullable — exercises with same group number are a superset |
| notes | Text | nullable — exercise-level notes |
| created_at | DateTime | |

### `workout_sets`
Individual sets within a workout exercise.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| workout_exercise_id | UUID | FK → workout_exercises |
| set_number | Int | order within the exercise |
| notes | Text | nullable |
| created_at | DateTime | |

> All set data (reps, weight, RPE, rest, tempo, and any user-defined fields) is stored in `workout_set_values`. The set itself is just a container with ordering.

### `workout_set_values`
All field values for a specific set. One row per field per set.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| workout_set_id | UUID | FK → workout_sets |
| field_definition_id | UUID | FK → exercise_field_definitions |
| value_number | Float | nullable — used when field_type = "number" |
| value_text | String | nullable — used when field_type = "text" or "select" |
| value_toggle | Boolean | nullable — used when field_type = "toggle" |

> To compute volume, 1RM, or PRs, the app queries `workout_set_values` joined with `exercise_field_definitions` where `system_key = "reps"` or `system_key = "weight"`. This gives the same computation power as hardcoded columns while allowing full flexibility.

### `flags`
User-defined tags/labels.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Deload", "PR Attempt", "Warm-up" |
| color | String | hex color code |
| icon | String | nullable — SF Symbol name or emoji |
| scope | String | "workout" / "exercise" / "set" — where this flag can be applied |
| created_at | DateTime | |

### `flag_assignments`
Many-to-many: flags applied to workouts, workout_exercises, or workout_sets.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| flag_id | UUID | FK → flags |
| workout_id | UUID | nullable — FK → workouts (if scope = "workout") |
| workout_exercise_id | UUID | nullable — FK → workout_exercises (if scope = "exercise") |
| workout_set_id | UUID | nullable — FK → workout_sets (if scope = "set") |
| created_at | DateTime | |

> **Constraint:** exactly one of workout_id / workout_exercise_id / workout_set_id must be non-null.

---

## 3. Nutrition Module

### `nutrient_definitions`
User-defined nutrients to track. Seeded with suggestions on first launch, fully customizable.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Calories", "Protein", "Creatine", "Caffeine" |
| unit | String | e.g., "kcal", "g", "mg", "mcg" |
| is_default | Boolean | true for system-seeded nutrients — can be hidden but not deleted |
| sort_order | Int | display order |
| is_visible | Boolean | default true — whether to show in Daily Log UI |
| api_key | String | nullable — mapping key for external food API fields (e.g., "proteins", "carbohydrates") |
| created_at | DateTime | |

> On first launch, the app seeds suggested nutrients: Calories (kcal), Protein (g), Carbs (g), Fat (g). These are marked `is_default = true`. The user can hide them, rename them, reorder them, or add any new nutrient they want (e.g., "Creatine", "Caffeine", "Fiber", "Omega-3"). Custom nutrients have `api_key = null` since they won't auto-populate from food databases — the user enters values manually. System-seeded nutrients have `api_key` set so food database imports can auto-fill them.

### `food_items`
Cached food database entries (from API or user-created).

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | nullable — null = from external API, non-null = user-created |
| external_id | String | nullable — ID from external food API (for deduplication) |
| barcode | String | nullable — EAN/UPC barcode |
| name | String | e.g., "Chicken Breast, Grilled" |
| brand | String | nullable |
| serving_size_g | Float | default serving size in grams |
| serving_unit | String | e.g., "g", "ml", "piece", "cup" |
| is_favorite | Boolean | default false |
| last_used_at | DateTime | nullable — for "recent" sorting |
| created_at | DateTime | |
| updated_at | DateTime | |

### `food_item_nutrients`
Nutrient values for a food item. One row per food item per nutrient.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| food_item_id | UUID | FK → food_items |
| nutrient_definition_id | UUID | FK → nutrient_definitions |
| value_per_serving | Float | amount per serving in the nutrient's unit |

> When importing from an external food API, the app matches API response fields to `nutrient_definitions.api_key` and creates rows for each match. Nutrients the API doesn't provide simply have no row (not zero). When the user creates a custom food, they fill in whichever nutrients they want — missing ones are absent, not zero.

### `recipes`
User-created combinations of food items.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Post-Workout Shake" |
| servings | Int | how many servings this recipe makes |
| notes | Text | nullable |
| created_at | DateTime | |
| updated_at | DateTime | |

### `recipe_ingredients`
Food items within a recipe.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| recipe_id | UUID | FK → recipes |
| food_item_id | UUID | FK → food_items |
| quantity | Float | number of servings of this food item |
| sort_order | Int | |

### `meal_categories`
User-defined meal slots. Seeded with defaults on first launch.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Breakfast", "Pre-Workout", "Midnight Snack" |
| sort_order | Int | display order |
| is_default | Boolean | true for system-seeded slots (Breakfast, Lunch, Dinner, Snack) |
| created_at | DateTime | |
| updated_at | DateTime | |

> On first launch, the app seeds 4 default categories: Breakfast (sort 0), Lunch (sort 1), Dinner (sort 2), Snack (sort 3). Users can rename, reorder, add, or delete these. Default categories can be renamed but not deleted.

### `meal_entries`
Individual food log entries.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| date | Date | |
| meal_category_id | UUID | FK → meal_categories |
| food_item_id | UUID | nullable — FK → food_items (if logging a single food) |
| recipe_id | UUID | nullable — FK → recipes (if logging a recipe) |
| quantity | Float | number of servings |
| logged_at | DateTime | timestamp of when the meal was eaten (for timing correlations) |
| notes | Text | nullable |
| created_at | DateTime | |

> **Constraint:** exactly one of food_item_id / recipe_id must be non-null.

### `meal_templates`
Saved combinations of foods for quick logging. Distinct from recipes — a template is "what I usually eat for breakfast" (a collection of separate food entries), while a recipe is a single combined food with specific ratios.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Usual Breakfast", "Pre-Workout Meal" |
| meal_category_id | UUID | nullable — FK → meal_categories (default slot when logging) |
| created_at | DateTime | |
| updated_at | DateTime | |

### `meal_template_items`
Individual food items within a meal template.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| meal_template_id | UUID | FK → meal_templates |
| food_item_id | UUID | nullable — FK → food_items |
| recipe_id | UUID | nullable — FK → recipes |
| quantity | Float | number of servings |
| sort_order | Int | |

> **Constraint:** exactly one of food_item_id / recipe_id must be non-null.

### `nutrition_targets`
User-defined daily goals. One row per nutrient the user sets a target for.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| nutrient_definition_id | UUID | FK → nutrient_definitions |
| target_value | Float | daily target in the nutrient's unit |
| updated_at | DateTime | |

> **Unique constraint:** (user_id, nutrient_definition_id). The user only creates targets for nutrients they care about. Nutrients without a target row simply show totals without a progress bar.

---

## 4. Lifestyle Module

### `daily_logs`
One entry per user per day. HealthKit data is auto-populated; manual tracking goes through `daily_log_field_definitions` + `daily_log_values`.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| date | Date | unique per user |
| sleep_hours | Float | nullable — from HealthKit or manual |
| sleep_deep_minutes | Int | nullable — from HealthKit |
| sleep_core_minutes | Int | nullable — from HealthKit |
| sleep_rem_minutes | Int | nullable — from HealthKit |
| steps | Int | nullable — from HealthKit |
| resting_heart_rate | Int | nullable — from HealthKit (bpm) |
| hrv | Float | nullable — from HealthKit (ms) |
| active_energy_kcal | Float | nullable — from HealthKit |
| walking_distance_km | Float | nullable — from HealthKit |
| notes | Text | nullable |
| created_at | DateTime | |
| updated_at | DateTime | |

> **Unique constraint:** (user_id, date). HealthKit columns are hardcoded because they map to Apple's fixed API types. All user-defined manual tracking (body weight, water, caffeine, supplements, etc.) goes through the flexible field system below.

### `daily_log_field_definitions`
User-defined fields for daily tracking. The user creates whatever they want to track daily.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Body Weight", "Water", "Caffeine", "Creatine" |
| field_type | String | "number" / "text" / "toggle" |
| unit | String | nullable — e.g., "kg", "L", "mg" |
| system_key | String | nullable — identifies system-seeded fields: "body_weight". Null for user-created fields |
| sort_order | Int | display order |
| is_active | Boolean | default true |
| is_default | Boolean | true for system-seeded fields — can be hidden but not deleted |
| created_at | DateTime | |

> On first launch, the app seeds one default: Body Weight (number, kg, `system_key: "body_weight"`). The user can add any field they want: "Water" (number, L), "Caffeine" (number, mg), "Meditation" (number, minutes), "Took Creatine" (toggle), etc. Each field appears as a row in the Daily Log for daily entry. `system_key: "body_weight"` lets the app apply HealthKit precedence logic and feed body weight into correlations.

### `daily_log_values`
Values for user-defined daily fields. One row per field per day.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| daily_log_id | UUID | FK → daily_logs |
| field_definition_id | UUID | FK → daily_log_field_definitions |
| value_number | Float | nullable — used when field_type = "number" |
| value_text | String | nullable — used when field_type = "text" |
| value_toggle | Boolean | nullable — used when field_type = "toggle" |

> **Unique constraint:** (daily_log_id, field_definition_id). All user-defined daily values feed into the correlation engine as factor variables.


---

## 5. Correlation Engine (Cache)

### `correlation_results`
Cached results of pre-computed correlations. Stored on-device only.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| target_variable | String | e.g., "squat_estimated_1rm", "total_volume", "bench_press_weight" |
| factor_variable | String | e.g., "sleep_hours", "daily_carbs_g", "protein_g" |
| test_method | String | "spearman" / "point_biserial" / "mann_whitney" / "bucket_comparison" — see CORRELATION_ENGINE.md |
| lag_days | Int | 0–7 — which time lag produced the best result |
| effect_size | Float | standardized effect size (Cohen's d for comparisons, r for correlations) |
| p_value | Float | statistical significance (after BH correction) |
| sample_size | Int | number of data points used |
| mean_high | Float | nullable — mean target value when factor is high/on |
| mean_low | Float | nullable — mean target value when factor is low/off |
| effect_description | String | plain-language summary for UI |
| confidence_badge | String | "strong" / "moderate" / "early_trend" |
| is_significant | Boolean | adjusted p < 0.05 AND n ≥ 20 |
| data_completeness | Float | 0–1 — fraction of days in range that had both variables present |
| computed_at | DateTime | when this was last calculated |

> **Note:** only rows where `is_significant = true` are surfaced to the user. See `docs/CORRELATION_ENGINE.md` for test selection logic, confidence badge thresholds, and multiple comparison correction details.

---

## Entity Relationship Summary

```
users
 ├── exercises
 │    └── exercise_field_definitions
 │         └── workout_set_values → workout_sets
 ├── workouts
 │    └── workout_exercises
 │         └── workout_sets
 ├── workout_templates
 │    └── workout_template_exercises → exercises
 │         └── workout_template_field_targets → exercise_field_definitions
 ├── flags
 │    └── flag_assignments → (workouts | workout_exercises | workout_sets)
 ├── nutrient_definitions
 │    ├── food_item_nutrients → food_items
 │    └── nutrition_targets
 ├── food_items (user-created)
 ├── recipes
 │    └── recipe_ingredients → food_items
 ├── meal_categories
 ├── meal_entries → meal_categories, (food_items | recipes)
 ├── meal_templates → meal_categories
 │    └── meal_template_items → (food_items | recipes)
 ├── daily_log_field_definitions
 │    └── daily_log_values → daily_logs
 ├── daily_logs
 └── correlation_results (on-device only)
```

## Indexes

Key indexes for query performance:

- `workouts(user_id, date)` — workout history queries
- `workouts(user_id, status)` — find in-progress workouts
- `workout_sets(workout_exercise_id)` — loading sets for a workout
- `workout_set_values(workout_set_id)` — loading field values for a set
- `exercise_field_definitions(exercise_id, sort_order)` — ordered fields for an exercise
- `workout_templates(user_id)` — list user's templates
- `meal_entries(user_id, date)` — daily nutrition view
- `meal_entries(meal_category_id)` — entries per meal slot
- `meal_categories(user_id, sort_order)` — ordered meal slots
- `meal_templates(user_id)` — list user's meal templates
- `daily_logs(user_id, date)` — unique, daily lookup
- `daily_log_field_definitions(user_id, sort_order)` — ordered daily fields
- `daily_log_values(daily_log_id)` — load values for a day
- `food_items(barcode)` — barcode scan lookup
- `food_items(user_id, last_used_at)` — recent foods
- `food_item_nutrients(food_item_id)` — load nutrients for a food
- `nutrient_definitions(user_id, sort_order)` — ordered nutrient list
- `nutrition_targets(user_id)` — load user's targets
- `flag_assignments(flag_id)` — filter by flag
- `correlation_results(user_id, is_significant)` — load significant correlations
