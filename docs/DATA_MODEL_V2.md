# GHISA — Data Model: V2 & Future Reference

Items removed from the V1 data model because they are out of scope per the PRD. Preserved here for future implementation.

---

## Authentication Fields (V2 — Backend + Auth)

Add to `users` when backend and authentication are implemented:

| Column | Type | Notes |
|--------|------|-------|
| password_hash | String | nullable (not used for Apple Sign-In) |
| apple_user_id | String | nullable, unique — Apple Sign-In identifier |

---

## Subjective Ratings (V2 — Manual Lifestyle Data)

Add to `daily_logs` when subjective daily ratings are implemented:

| Column | Type | Notes |
|--------|------|-------|
| stress_level | Int | nullable — manual (1–10) |
| energy_level | Int | nullable — manual (1–10) |
| mood_level | Int | nullable — manual (1–10) |
| soreness_level | Int | nullable — manual (1–10) |

---

## Body Measurements (V2)

### `body_measurements`
Periodic body measurement tracking.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| date | Date | |
| notes | Text | nullable |
| created_at | DateTime | |

### `measurement_definitions`
User-defined measurement types.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | String | e.g., "Left Arm", "Chest", "Waist", "Neck" |
| unit | String | "cm" or "in" |
| sort_order | Int | |
| is_active | Boolean | default true |
| created_at | DateTime | |

### `measurement_values`
Individual measurements taken.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| body_measurement_id | UUID | FK → body_measurements |
| measurement_definition_id | UUID | FK → measurement_definitions |
| value | Float | the measured value |

---

## Progress Photos (V2)

### `progress_photos`
Optional photos linked to a measurement session.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| body_measurement_id | UUID | FK → body_measurements |
| file_path | String | local file path on device |
| pose_type | String | nullable — "front" / "side" / "back" / "other" |
| created_at | DateTime | |

> **Note:** progress photos are stored **locally only** — never synced to backend.

---

## Sync (V2 — Backend + Cloud Sync)

### `sync_queue`
Pending changes to sync to the backend. On-device only.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| entity_type | String | e.g., "workout", "meal_entry", "daily_log" |
| entity_id | UUID | ID of the changed record |
| action | String | "create" / "update" / "delete" |
| payload | JSON | the full entity data to sync |
| created_at | DateTime | when the change was made |
| synced_at | DateTime | nullable — null means pending |
| retry_count | Int | default 0 |
| last_error | String | nullable — last sync error message |

---

## Conventions Deferred to V2

### Body Weight Precedence (with Body Measurements)
When `body_measurements` is implemented: body weight can appear in two places — `daily_log_values` (via `system_key: "body_weight"`) and `body_measurements` (periodic). For the correlation engine and charts:
- **`daily_log_values`** is the primary source.
- `body_measurements` are for circumference tracking sessions and may include a weight entry, but this does not override the daily log for the same date.
- If no body weight daily log value exists for a date but a `body_measurements` entry exists with a weight-type measurement, the engine may use it as a fallback.

### Measurement Unit Convention
- Circumferences: **cm** — `measurement_values.value`
- The app converts to imperial for display when `users.unit_system = "imperial"`.
