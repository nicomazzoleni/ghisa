# GHISA — Product Requirements Document (PRD)

## 1. Product Overview

**GHISA** is a native iOS app that centralizes gym performance, nutrition, and lifestyle data into a single platform. It is built on two core principles:

1. **Radical customizability** — both the training logger and nutrition tracker give the user the same unrestricted freedom as pen and paper. The user decides what to track, how to organize it, and what metadata matters. No rigid templates, no opinionated defaults.
2. **A correlation engine** that reveals statistically significant relationships between all tracked variables and gym performance — answering questions like *"How much does an extra hour of sleep improve my squat?"* or *"Do high-carb days actually help my bench press?"*

Together, these solve a problem no existing app addresses: advanced lifters track meticulously but have no way to understand the trends hidden in their own data.

### 1.1 Vision
Replace the fragmented stack of fitness apps (one for training, one for food, one for sleep) with a unified system where all data lives together and can be cross-analyzed — while matching or exceeding the flexibility of each individual tool.

### 1.2 Target User
Intermediate-to-advanced gym goers who already track their training meticulously (often on paper or in rigid apps) and want:
- A logging tool as flexible as a notebook but with the benefits of structured data
- Data-driven insights into what actually moves the needle on their performance
- One app instead of three

These users are already disciplined loggers. The app does not need to motivate them to track — it needs to give them a tool worthy of their discipline and reward them with insights no other app can provide.

### 1.3 Tech Stack
- **iOS Frontend:** Swift / SwiftUI (iOS 17+), SwiftData
- **Computation:** On-device (Swift Accelerate framework)
- **Health Integration:** Apple HealthKit
- **Nutrition Data:** Open Food Facts API (primary), USDA FoodData Central (fallback for raw ingredients)

### 1.4 V1 Scope Boundaries

**In scope:**
- Training module (full)
- Nutrition module (full — in-app tracker with Open Food Facts)
- Lifestyle data via HealthKit (automatic — sleep, steps, HRV, heart rate, active energy, distance)
- Body weight (HealthKit pull + manual entry)
- Correlation engine (full)
- Insights dashboard (full)

**Out of scope for V1:**
- Backend / server / API
- User authentication (single-device, no account)
- Data sync (local only)
- Subjective ratings (stress, energy, mood, soreness) — V2, after validating hard data correlations
- Body measurements (circumferences) — V2
- Progress photos — V2

---

## 2. Training Module — "Digital Paper Notebook"

### 2.1 Design Philosophy
The user should feel the same unrestricted freedom they have with a physical notebook. No rigid templates forced on them. They decide what to track, how to organize it, and what metadata matters.

Every lifter has their own system — some track tempo, some track grip width, some care about rest times, others don't. The app adapts to the user's system, not the other way around.

### 2.2 Exercises

- **Custom exercise creation:** user defines name, muscle group(s), movement type (push/pull/hinge/squat/carry/isolation/cardio/other)
- **Custom fields per exercise:** each exercise can have user-defined fields beyond the defaults. Field types supported:
  - **Number** (e.g., grip width in cm, incline angle, distance in km)
  - **Text** (e.g., notes, cues)
  - **Dropdown / single-select** (e.g., grip type: overhand / underhand / neutral)
  - **Toggle / boolean** (e.g., belt: yes/no)
- **Default fields** (always available, optionally hideable per exercise): reps, weight, RPE, rest time, tempo
- **Exercise library:** user's created exercises are stored and reusable
- **Exercise editing:** user can rename an exercise or change its muscle groups/movement type at any time. Since all historical data references the exercise by ID (not name), renaming automatically updates how past workouts display — no data is lost or orphaned. Renaming does not break correlation history.
- **Exercise archiving:** deleting an exercise soft-deletes it (archived). Archived exercises no longer appear in search or the exercise library, but all historical workout data referencing them is preserved and visible in workout history. An archived exercise can be restored.
- **Exercise search:** quickly find exercises by name or muscle group

### 2.3 Workouts (Training Sessions)

- **Freeform logging:** add any exercise, any number of sets, in any order
- **Set-level data:** each set records the exercise's active fields (reps, weight, custom fields)
- **Reorder:** drag-and-drop to reorder exercises and sets within a workout
- **Supersets / circuits:** ability to group exercises together
- **Workout metadata:** date, start time, end time (duration auto-calculated), location (optional), general notes
- **In-progress state:** workouts are auto-saved continuously as the user logs sets. If the app is backgrounded, force-quit, or crashes, the in-progress workout is preserved and restored on next app open. The Train tab shows a persistent "Resume Workout" banner when an unfinished session exists. A workout remains in-progress until the user explicitly taps "Finish" or "Discard." Discarding requires confirmation.
- **Copy previous workout:** duplicate a past session as a starting point. Copies the exercise list, set structure, AND the weight/rep values from that session (pre-filled as targets to match or beat). User can edit anything before or during the session.
- **Workout templates:** save a workout structure (exercises + set count + optional target weights/reps) as a reusable template. Templates are separate from workout history — editing a template does not affect past workouts logged from it. Users can create templates from scratch or save any completed workout as a template.

### 2.4 Custom Flags

A powerful tagging system that lets users annotate their data at any level of granularity:

- **Flag creation:** user defines flag name, color, icon, and **scope** (where it can be applied):
  - **Workout-level flags** — e.g., "Deload", "Competition Prep", "Morning Session", "Fasted"
  - **Exercise-level flags** — e.g., "PR Attempt", "Technique Focus", "Paused Reps"
  - **Set-level flags** — e.g., "Failed Rep", "Spotter Assisted", "Drop Set", "Warm-up"
- **Multi-flag support:** multiple flags can be applied to the same item
- **Flag filtering:** view training history filtered by flags (e.g., show all "Fasted" workouts)
- **Flags feed into correlations:** flags become queryable variables in the correlation engine (e.g., "Do I perform better on 'Morning Session' vs evening?")

### 2.5 Training History & Progress

- **Workout history:** scrollable timeline of past workouts
- **Exercise history:** per-exercise view showing all logged sets over time
- **Personal records (PRs):** auto-detected per exercise (heaviest weight, most reps at a given weight, estimated 1RM)
- **Progress charts:** weight/volume over time per exercise
- **Search & filter:** by date range, exercise, flag, muscle group

---

## 3. Nutrition Module — "Digital Food Notebook"

### 3.1 Design Philosophy

The same "paper notebook" freedom applies to nutrition. The user decides what they care about tracking. Some users want macro-level precision. Others just want to log calories and protein. The app should never force fields or workflows on the user.

Key principles:
- **The user's existing food tracking habits should feel faster here, not slower.** Quick log, favorites, barcode scanning, and copy-day exist to minimize friction.
- **Customizability over comprehensiveness.** The user can create custom foods, custom meal slots, and choose which nutritional fields matter to them — rather than being overwhelmed by 50 micronutrients they don't care about.
- **Every logged data point feeds the correlation engine.** Meal timing, macros, micros, and custom nutrition fields all become variables that can be analyzed against training performance.

### 3.2 Food Database

- **Primary source:** Open Food Facts API — open-source, community-maintained database with ~3M products and barcode coverage for packaged foods
- **Secondary source:** USDA FoodData Central — used as a fallback for raw/unpackaged ingredients (chicken breast, rice, oats, eggs) where Open Food Facts data is sparse or unreliable
- **Data quality handling:** entries with clearly invalid data (e.g., calories = 0 with non-zero macros, or macros that don't approximately sum to calories) are flagged for user review rather than silently accepted. The user can edit any food's nutrition values after importing.
- **Offline food search:** all foods the user has previously searched, logged, or created are cached locally in `food_items`. When offline, search operates against this local cache only. When online, search queries the external API and caches new results. The app never pre-downloads the full external database — only user-touched items are cached.
- **Barcode scanning:** scan packaged food to auto-populate nutrition data. Scanned items are cached locally for future offline use.
- **Custom food creation:** user can create foods not in any database, entering whatever nutritional data they have. Missing fields are stored as null (not zero).
- **Edit any food:** user can edit the nutrition values of any cached food item (API-sourced or custom). Edits are local — they don't affect the external database. This lets users correct bad data from Open Food Facts.
- **Recent & favorites:** quick access to frequently logged foods, sorted by recency and frequency

### 3.3 Meal Logging

- **Meal categories:** Breakfast, Lunch, Dinner, Snacks as defaults. User can rename, reorder, add, or remove meal slots (e.g., "Pre-Workout", "Post-Workout", "Midnight Snack"). Custom meal slots are first-class — they work identically to the defaults.
- **Per-entry data:** food item, serving size, quantity. Serving size can be entered in grams (always available) or in the food's defined serving unit (e.g., "1 piece", "1 cup"). When a non-gram unit is used, the gram equivalent is stored alongside it (derived from `serving_size_g`) so that nutrition math is always weight-based internally. The user sees both: "1 piece (150g)".
- **Meal timestamps:** each meal entry records when the food was eaten (user-editable, defaults to current time). This enables meal-timing correlations with training performance.
- **Quick log:** repeat a previous meal with one tap
- **Copy day:** duplicate an entire day's meals

### 3.4 Nutritional Tracking

- **Macronutrients:** calories, protein, carbohydrates, fat (always tracked)
- **Micronutrients (available but user-controlled):**
  - Fiber, Sugar, Sodium, Iron, Calcium, Vitamin D, Vitamin B12, Potassium, Magnesium
  - The user chooses which micronutrients to display in their daily view. Hidden micros are still stored (when available from the food database) and still feed into correlations — they're just not shown in the daily UI unless the user opts in.
- **Daily targets:** user sets macro/micro goals; visual progress bars show completion. Targets are optional — the app works fine without them.
- **Meal timing:** each meal entry has a timestamp, enabling correlation analysis with training time (e.g., "hours since last meal before training")

### 3.5 Recipes & Meal Templates

- **Recipe builder:** combine multiple food items into a recipe with a total nutrition breakdown
- **Serving-based logging:** log X servings of a recipe instead of individual ingredients
- **Meal templates:** save a combination of foods as a reusable meal (distinct from recipes — a template is "what I usually eat for breakfast" while a recipe is "my protein shake with specific ingredients and ratios")

### 3.6 Nutrition Summaries

- **Daily view:** all meals + totals for the day with target comparison
- **Weekly view:** average daily intake over the week
- **Macro breakdown:** pie chart (protein/carbs/fat ratio)

---

## 4. Lifestyle Module — HealthKit Integration

### 4.1 Design Philosophy

Lifestyle data should be **fully passive** in V1. The user should not need to manually enter anything except body weight (for users without a HealthKit-connected scale). All other data is pulled automatically from Apple Health, which aggregates from Apple Watch, connected apps, and connected devices.

This keeps the daily logging burden to: workouts (intentional) + meals (intentional) — no extra forms to fill out.

### 4.2 Automatic Data (HealthKit)

Data pulled automatically from Apple Health (with user permission):

| Data Point | HealthKit Type | Unit |
|---|---|---|
| Sleep duration | `sleepAnalysis` | hours |
| Sleep stages (if available) | `sleepAnalysis` | deep/core/REM minutes |
| Daily steps | `stepCount` | count |
| Resting heart rate | `restingHeartRate` | bpm |
| Heart rate variability (HRV) | `heartRateVariabilitySDNN` | ms |
| Active energy burned | `activeEnergyBurned` | kcal |
| Walking + running distance | `distanceWalkingRunning` | km |
| Body weight | `bodyMass` | kg |

- **Background sync:** data pulled on app open and after returning from background
- **Historical import:** on first HealthKit authorization, import last 90 days of data
- **Body weight:** pulled from HealthKit if available (Apple Watch, smart scale, or other apps). Also available as a manual entry field in the Daily Log for users without a connected scale. HealthKit value takes precedence if both exist for the same date.

### 4.3 What HealthKit Does NOT Provide

For clarity, the following are **not available** via HealthKit and are intentionally excluded from V1:

- Stress level, energy level, mood, soreness (subjective — would require manual entry)
- Meal timing (HealthKit nutrition samples lack per-meal granularity — handled by the in-app nutrition tracker instead)
- Training data (HealthKit workout data is too coarse for serious lifting — handled by the in-app training module)

---

## 5. Correlation & Insights Engine (Core Value Proposition)

### 5.1 How It Works

The engine computes statistical relationships between any two tracked variables across time. It uses the user's own historical data to surface personalized insights.

> **Technical details** — statistical methodology, variable type classification, test selection per variable pair, multiple comparison correction, confidence badge thresholds, derived variable computation, and edge case handling are documented in [`docs/CORRELATION_ENGINE.md`](./CORRELATION_ENGINE.md). This section covers the user-facing behavior only.

### 5.2 Variable System

Every tracked data point becomes a queryable **variable**:

**Training variables:**
- Volume per session (total sets x reps x weight)
- Volume per muscle group
- Estimated 1RM per exercise
- Number of sets to failure
- Average RPE per session
- PR frequency
- Any custom flag (as binary yes/no)

**Nutrition variables:**
- Total daily calories
- Daily protein / carbs / fat (grams and % of total)
- Any tracked micronutrient
- Meal timing relative to training (hours before/after)
- Caloric surplus/deficit (if the user manually sets a calorie target)

**Lifestyle variables (from HealthKit):**
- Sleep duration
- Sleep quality / stages (if available)
- Steps
- Resting heart rate
- HRV
- Active energy burned
- Body weight
- Training day vs rest day

### 5.3 User-Friendly Design Philosophy

The target user does **not** have deep statistical knowledge. The app must:
- **Hide complexity:** all statistical computation happens behind the scenes — the user never sees p-values, r-coefficients, or formulas
- **Speak plain language:** insights are presented as simple, human-readable statements with clear visual indicators (color-coded: green = positive impact, red = negative impact, gray = no clear effect)
- **Guide the user:** when users want to explore custom analyses, the app suggests what to compare, what controls to use, and explains why

### 5.4 Pre-Built Insight Cards (Automatic)

The app automatically computes and displays a curated set of insight cards organized by category. These run in the background as data accumulates.

**Sleep & Recovery insights:**
- "You lift **X% more volume** when you sleep over Y hours"
- "Your performance drops noticeably when sleep is below Y hours"
- "Sleep **2 nights before** training affects your performance more than last night's sleep" (time-lag detection)

**Nutrition insights:**
- "High-carb days (>Xg) are associated with **stronger sessions**"
- "Your best sessions happen when you eat **X–Y grams of protein** the day before"
- "Training within X hours of a meal correlates with **better/worse** performance"
- "You tend to perform better on days with higher total calorie intake"

**Lifestyle & Activity insights:**
- "You perform **X% better** in morning vs evening sessions" (or vice versa)
- "Higher step counts on rest days correlate with **better next-day performance**"
- "Your HRV above X ms is associated with **stronger sessions**"

**Body composition insights:**
- "Your strength tends to increase when your body weight is trending **up/stable/down**"

**How cards are presented:**
- Each card shows: a clear statement, a simple visual (bar comparison, trend arrow, or mini chart), and a **confidence badge** (e.g., "Based on 45 data points" / "Strong finding" / "Early trend — more data needed")
- Cards are ranked by **strength and actionability** — the most impactful findings appear first
- Cards refresh weekly as new data comes in
- Users can dismiss/hide cards they don't find useful
- Tapping a card expands it to show a simple chart (bar chart, trend line, or comparison visual — NOT a scatter plot with regression lines)

### 5.5 Significance-Gated Analysis ("Explore")

For users who want to go beyond the pre-built cards, the app offers a **guided exploration mode.** Crucially, **the user can only explore analyses that are statistically significant.** The engine pre-computes all possible correlations in the background and filters out noise — the user never sees dead-end analyses.

#### Background Pre-Computation

- The engine periodically scans **all pairwise combinations** of target variables x factor variables (including time lags 0–7 days)
- Each pair is tested for statistical significance (p < 0.05) and minimum data (n >= 20)
- Only pairs that pass both thresholds are flagged as **"available for exploration"**
- This runs in the background (e.g., on app open, after new data is logged, or weekly batch)

#### Guided Explore Flow

**Step 1 — Pick what you want to understand:**
- User selects a **target variable** (what they want to improve), e.g., "Squat performance", "Total training volume", "Bench press weight"
- Presented as a simple list grouped by exercise or category
- **Only targets that have at least one significant factor are shown.** Targets with no significant correlations are hidden entirely (not grayed out — just absent)

**Step 2 — Pick what's influencing it:**
- The app shows **only the factors that have a statistically significant relationship** with the chosen target
- Factors are ranked by effect strength (strongest first)
- Each factor shows a preview hint: e.g., "Sleep — strong positive effect", "Stress — moderate negative effect"
- **There is no "See all" option** — if a factor doesn't appear, it means the data doesn't support a meaningful link. This prevents the user from running meaningless analyses
- If only 1 significant factor exists, the app can auto-select it and move to results

**Step 3 — Results displayed simply:**
- The app auto-determines the best configuration (optimal time lag, rolling average window, date range) — no user input needed
- Shows a plain-language explanation: *"We're comparing your squat performance on days when you ate more vs fewer carbs the day before, averaged over the last 3 months"*
- **Comparison visual:** "When [factor] is HIGH, your [target] averages X. When [factor] is LOW, your [target] averages Y" — shown as a clear bar chart comparison
- **Trend line:** simple line chart showing both variables over time on the same timeline
- **Verdict badge:** plain-language conclusion — "Strong positive effect", "Slight positive effect", "Slight negative effect", "Strong negative effect" (no "No clear effect" — those are filtered out before the user ever sees them)
- **What this means:** one-sentence human-readable interpretation, e.g., *"Eating more than 200g of carbs the day before training is associated with lifting 8% more volume"*
- **Caveat footer:** subtle reminder — *"Based on your personal data. Correlation doesn't prove one thing causes another."*
- User can optionally adjust: time window and lag ("same day" vs "day before" vs "2 days before") — but only among configurations that remain significant

**Step 3.5 (Optional) — "Only when..." filters:**

After viewing results, the user can refine the analysis by adding condition filters. Each filter is built with structured controls — no free-text input, no AI interpretation.

- A button labeled **"Add filter"** appears below the results
- Tapping it opens a **filter builder** with three structured steps:
  1. **Pick a variable** — list of other tracked variables (sleep hours, calories, body weight, flags, etc.), excluding the current target and factor
  2. **Pick an operator** — depends on the variable type:
     - **Numeric variables** (sleep, calories, etc.): `>`, `<`, `>=`, `<=`, `=`, `between`
     - **Boolean/flag variables** (training day, "Fasted" flag, etc.): `is on` / `is off`
     - **Categorical variables** (session time-of-day bucket, etc.): `is` / `is not` with a dropdown of possible values
  3. **Pick a value** — input matched to variable type:
     - Numeric: number input or slider (pre-filled with the variable's median as a sensible default, showing min/max range from user's data)
     - Boolean: toggle
     - Categorical: dropdown
- Each added filter appears as a **removable chip** below the results header (e.g., `Sleep > 7h ✕`, `Protein > 150g ✕`)
- **No limit on stacked filters** — the user can add as many as they want. The significance gate is the natural limiter: after each filter is added, the engine re-evaluates the analysis. If the filtered dataset drops below n ≥ 20 or the result is no longer significant (p < 0.05), the app shows a warning: *"Not enough data with these filters to draw a conclusion. Try removing a filter."* and the results are hidden until filters are adjusted
- **Available variables are always shown** — unlike the Explore factor list (which hides insignificant options), the filter variable list shows all tracked variables. The user is free to try any filter combination; the significance gate catches dead ends after the fact rather than before, since filter interactions are too numerous to pre-compute
- After applying filters, the results update with a revised explanation: *"Comparing your squat volume on high-carb vs low-carb days — filtered to days where sleep > 7h"*
- If no data remains after filtering: *"No data points match all your filters. Try widening or removing some."*

#### "What Matters Most" Summary

On the Step 3 results screen, below the primary factor analysis, the app can optionally show a **ranked summary** of all significant factors for the chosen target:

- Header: **"Everything that affects your [target]"**
- Ranked list of all significant factors, each showing: factor name, direction (up/down arrow, green/red), and relative strength (e.g., "Sleep: strong positive", "Carbs: slight positive")
- Factors are ranked using **partial correlation** (each factor's unique contribution after accounting for shared variance with other factors) — but this is never explained to the user, it's just presented as a ranked list
- If a factor that was significant in pairwise analysis drops to insignificant after accounting for other variables, it appears dimmed with a note: *"This may be explained by other factors"*
- Tapping any factor in the list navigates to its own Explore result (Step 3)

This answers the question *"What actually matters vs. what just looks like it matters?"* without requiring the user to understand multivariate statistics.

#### Empty State

- If the user has insufficient data for any significant correlations: *"Keep logging! We need more data to find meaningful patterns. You have X days logged — significant insights usually emerge around 30–60 days."*
- If a specific target has no significant factors: that target simply doesn't appear in the Explore list

### 5.6 Data Requirements & Guardrails

- **Significance gate:** analyses are only surfaced to the user if they pass statistical significance (p < 0.05 internally). The user never encounters a "no pattern found" result because insignificant pairs are filtered before presentation
- **Minimum data:** correlations require at least **20 matching data points**; below this, the pair is excluded from both insight cards and Explore
- **Confidence levels:** displayed as simple badges on results that DO pass the gate:
  - "Strong finding" (large effect + large sample)
  - "Moderate finding" (medium effect or medium sample)
  - "Early trend" (just crossed significance threshold, small sample)
- **No statistical jargon:** never show p-values, r-values, or confidence intervals to the user
- **Confounding awareness:** if the app detects that the chosen factor is highly linked to another variable, show a gentle note: *"Note: this might also be related to [other variable]"* — and offer the "Only when..." filter to isolate the effect. The "What Matters Most" summary further addresses this by ranking factors by their unique contribution rather than raw correlation
- **Re-evaluation:** as new data comes in, previously significant correlations may become insignificant (and vice versa). The engine re-evaluates periodically and updates available analyses accordingly

### 5.7 Insights Home Dashboard

Since Insights is the **home screen** (first tab), the dashboard must be engaging and useful from day one:

- **Onboarding state (< 20 days of data):** the home screen must be useful even before insights unlock. Show:
  - Progress tracker: "You've logged X days. Insights unlock at ~20 days!" with a visual progress bar
  - **Today's snapshot:** a compact summary of what the user has logged today (workout summary if trained, macro totals if meals logged, sleep/steps from HealthKit). This gives the home screen immediate utility as a daily dashboard even without correlations.
  - **Recent PRs:** any personal records hit in the last 7 days
  - **Logging streak:** consecutive days with data logged (gamification to encourage consistency)
  - Tips on what to log for better insights (rotate daily)
- **Active state (20+ days):** show top 3–5 insight cards, ranked by impact
- **Category sections:** insights grouped under "Sleep & Recovery", "Nutrition", "Lifestyle"
- **Explore button:** prominent CTA to start a guided custom analysis
- **Weekly digest:** optional summary notification: "This week's top finding: sleeping >7h was linked to 12% better performance"

---

## 6. User Profile & Settings

### 6.1 No Authentication (V1)

V1 is a single-device, local-only app. No account creation, no sign-in. The user's data lives entirely on their device via SwiftData.

### 6.2 User Profile

Stored locally, used for display preferences:

- Name (optional)
- Age, gender (optional)
- Height, weight (starting)
- Unit preference: metric / imperial

### 6.3 Data Export

- User can export all data as CSV or JSON
- This is the backup mechanism in V1 (no cloud sync)

---

## 7. UX / Navigation Structure

### 7.1 Tab Bar (Bottom Navigation) — 3 Tabs

| Tab | Icon | Primary Screen |
|---|---|---|
| **Insights** (Home) | Chart/brain | Insights dashboard — this is the landing screen |
| **Train** | Dumbbell | Today's workout / Start workout |
| **Daily Log** | Calendar + fork/knife | Nutrition + body weight daily view |

**Profile access:** user avatar / icon in the **top-right corner** of every screen. Tapping it opens a profile sheet with: personal info, settings, unit preferences, goals, data export, and app settings.

### 7.2 Daily Log Tab

The Daily Log tab is the nutrition and lifestyle hub for each day:

- **Top section:** date selector (swipe left/right to change day)
- **Nutrition section:** meal slots (user-configured) with quick-add, daily macro totals + progress bars toward targets
- **HealthKit section:** auto-populated data for the day (sleep, steps, HRV, heart rate, active energy, distance). Read-only display — the user doesn't input this data.
- **Body weight:** manual entry field (pre-filled from HealthKit if available)
- **Summary footer:** "Day completeness" indicator showing how much data has been logged (encourages complete logging for better insights)

### 7.3 Key User Flows

**App open (daily):**
1. Land on **Insights** home → see top insight cards or onboarding progress
2. Navigate to other tabs as needed

**Log a workout:**
1. Tap "Train" → "Start Workout"
2. Add exercises (search or recent)
3. For each exercise: add sets, fill in fields (reps, weight, custom fields — whatever the user has configured for that exercise)
4. Apply flags to sets/exercises/workout as desired
5. Tap "Finish" → workout saved with auto-calculated duration

**Log nutrition (daily):**
1. Tap "Daily Log" → today's date shown
2. Tap a meal slot → search food, scan barcode, or pick from recent/favorites → set serving size → nutrition auto-calculated
3. View daily macro totals and progress toward targets
4. Check "day completeness" to see if anything is missing

**Explore an insight:**
1. On Insights home → tap an insight card → see expanded visual (bar comparison, trend line) + plain-language explanation
2. Or tap "Explore" → guided 3-step custom analysis (pick target → pick factor → see results)

**Access profile / settings:**
1. Tap profile icon (top-right, any screen) → profile sheet opens
2. Edit personal info, change units, set goals, export data

---

## 8. Non-Functional Requirements

### 8.1 Performance
- App launch to usable: < 2 seconds
- Workout logging: zero perceived lag on input
- Correlation computation: < 3 seconds for any single query (up to 1 year of daily data)
- Offline-first: all features work without internet (nutrition search falls back to local cache)

### 8.2 Data Privacy & Security
- All data stored locally on-device via SwiftData
- No server, no cloud storage, no data transmission in V1
- HealthKit data stays on device (Apple requirement)
- No analytics or tracking SDKs
- Data export gives the user full ownership of their data

### 8.3 Compatibility
- iOS 17.0+ (required for SwiftData and @Observable)
- iPhone only for V1

### 8.4 Accessibility
- Dynamic Type support (scalable fonts)
- VoiceOver labels on all interactive elements
- Sufficient color contrast ratios

---

## 9. Future Scope (Not in V1)

These are explicitly **out of scope** for V1 but inform architectural decisions:

**V2 candidates (post-validation):**
- Subjective daily ratings (stress, energy, mood, soreness) — adds manual lifestyle variables to the correlation engine
- Body measurements (circumferences) + progress photos
- Backend + authentication + cloud sync
- Apple Watch companion app
- Weekly digest notifications
- LLM-powered filter suggestions in Explore

**Later:**
- iPad app
- Social features (share workouts, compare with friends)
- AI-powered workout suggestions based on correlation data
- Garmin / Fitbit / Whoop integration
- Android version
- Web dashboard
- Supplement tracking
- Integration with gym equipment (Bluetooth)

---

## 10. Success Metrics

- User logs training data at least 4x/week
- User logs nutrition data at least 5x/week
- User checks insights dashboard at least 2x/week
- Correlation engine surfaces at least 3 actionable insights per user after 60 days of consistent data
- Nutrition search (Open Food Facts + local cache) returns relevant results in < 2 seconds
