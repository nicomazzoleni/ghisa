# GHISA — Correlation Engine Technical Specification

This document covers the statistical methodology, variable classification, test selection, and computation rules for the correlation/insights engine. For user-facing behavior (how insights are displayed, Explore flow UX, filter UI), see [`docs/PRD.md`](./PRD.md) section 5.

All computation runs **on-device** using the Swift Accelerate framework. No user data is sent to the backend for analysis.

---

## 1. Variable Classification

Every tracked data point is classified by type, which determines which statistical test is used when it participates in an analysis.

### 1.1 Variable Types

| Type | Description | Examples |
|------|-------------|----------|
| **Continuous** | Numeric, can take any value in a range | sleep_hours, body_weight_kg, calories, protein_g, HRV, active_energy_kcal |
| **Ordinal** | Discrete numeric scale with meaningful order but non-uniform intervals | stress_level (1–10), energy_level (1–10), mood_level (1–10), soreness_level (1–10), RPE (1–10) |
| **Binary** | Two states (yes/no, on/off) | any flag (present/absent), training_day (yes/no) |
| **Categorical** | Multiple unordered categories | time_of_day_bucket (morning/afternoon/evening), movement_type, meal_type |

### 1.2 Variable Role

Each variable can serve as:
- **Target** — what the user wants to understand/improve (always continuous: e.g., estimated 1RM, total volume, weight lifted)
- **Factor** — what might influence the target (any type: sleep, stress, a flag, meal timing, etc.)

Targets are always continuous because the comparison visual ("when factor is HIGH, target averages X vs Y") requires a numeric outcome to compare.

### 1.3 Derived Variables

Some variables don't exist directly in the database and must be computed:

| Variable | Derivation | Notes |
|----------|-----------|-------|
| **Total session volume** | SUM(reps × weight_kg) across all sets in a workout | Only completed workouts |
| **Volume per muscle group** | Same as above, grouped by exercise.muscle_groups | A set counts toward all muscle groups of its exercise |
| **Estimated 1RM** | Epley formula: weight × (1 + reps/30) | Per exercise, using the heaviest qualifying set (reps ≤ 10) per session |
| **Average RPE per session** | Mean RPE across all sets where RPE is logged | Null if < 50% of sets have RPE |
| **Sets to failure** | Count of sets where RPE = 10 or "Failed Rep" flag is present | Per session |
| **PR frequency** | Count of new PRs in a rolling window | Per week or month |
| **Daily calories** | SUM across all meal_entries for that date | quantity × food_item.calories (or recipe-computed equivalent) |
| **Daily protein/carbs/fat** | Same pattern as calories | In grams |
| **Meal timing relative to training** | Time delta between last meal_entry.logged_at before workout.started_at | In hours. Null if no meal or no workout that day |
| **Caloric surplus/deficit** | daily_calories − estimated TDEE | TDEE estimated from user profile (Mifflin-St Jeor + activity multiplier). Clearly labeled as estimate. |
| **Training day vs rest day** | Binary: did the user have a completed workout on this date? | |
| **Time of day bucket** | Derived from workout.started_at | "morning" (5–11), "afternoon" (11–17), "evening" (17–22), "night" (22–5) |
| **Body weight trend** | 7-day rolling average of daily_logs.body_weight_kg | Smooths daily fluctuations |

---

## 2. Statistical Test Selection

The engine does NOT use a single test for everything. The test is selected based on the **factor type** (since the target is always continuous):

| Factor Type | Test | Output | Why |
|-------------|------|--------|-----|
| **Continuous** | Spearman rank correlation | ρ (rho), p-value | Handles non-linear monotonic relationships (e.g., "more sleep → better performance" even if the relationship isn't perfectly linear). Robust to outliers. |
| **Ordinal** | Spearman rank correlation | ρ, p-value | Same reasoning — ordinal scales have meaningful order but non-uniform intervals. Pearson would assume equal spacing between 3/10 and 4/10 stress, which is wrong. |
| **Binary** | Mann-Whitney U test | U statistic, p-value, + compute means for both groups | Non-parametric comparison of target values when factor is on vs off. More robust than t-test for small/skewed samples. |
| **Categorical** | Kruskal-Wallis H test | H statistic, p-value | Non-parametric one-way ANOVA equivalent. Used when factor has 3+ categories. If significant, follow up with pairwise Mann-Whitney between each category pair. |

### 2.1 Effect Size Calculation

p-values alone don't tell the user how big the effect is. Each test produces a standardized effect size:

| Test | Effect Size Metric | Thresholds |
|------|-------------------|------------|
| Spearman | |ρ| directly | Small: 0.1–0.3, Medium: 0.3–0.5, Large: > 0.5 |
| Mann-Whitney | Rank-biserial correlation r | Small: 0.1–0.3, Medium: 0.3–0.5, Large: > 0.5 |
| Kruskal-Wallis | Epsilon-squared (η²) | Small: 0.01–0.06, Medium: 0.06–0.14, Large: > 0.14 |

### 2.2 Bucket-Based Comparison (Supplementary)

For all factor types, the engine also computes a **bucket comparison** as the primary visual output:
- Split factor values into HIGH vs LOW (using the median as the split point for continuous/ordinal, or the natural groups for binary/categorical)
- Compute mean and standard deviation of the target in each bucket
- This produces the numbers shown in the UI: "When sleep > 7h, your squat averages 105kg. When sleep ≤ 7h, it averages 95kg."
- The percentage difference between buckets is what appears in insight cards ("10% more volume")

For continuous variables where the relationship may be non-linear (U-shaped, threshold, etc.), the engine also tests a **tercile split** (LOW / MEDIUM / HIGH) to detect non-monotonic patterns. If the middle tercile is significantly different from both extremes, flag as "possible non-linear relationship" internally and use the tercile comparison in the insight card instead of the binary split.

---

## 3. Multiple Comparison Correction

### 3.1 The Problem

With thousands of pairwise tests, 5% will appear significant by pure chance. Example: 20 exercises × 30 factors × 8 lags = 4,800 tests → ~240 expected false positives at p < 0.05.

### 3.2 Correction Method: Benjamini-Hochberg (BH)

The engine uses the **Benjamini-Hochberg procedure** to control the False Discovery Rate (FDR) at 5%:

1. Run all pairwise tests and collect raw p-values
2. Rank p-values from smallest to largest
3. Apply BH correction: adjusted_p = raw_p × (total_tests / rank)
4. Only results with adjusted_p < 0.05 are flagged as significant

**Why BH over Bonferroni:** Bonferroni is too conservative for exploratory analysis — it would eliminate most real findings along with the false ones. BH allows more discoveries while controlling the expected proportion of false discoveries at 5%, which is appropriate for a consumer app showing "likely real" patterns, not a clinical trial.

### 3.3 Grouping Tests for Correction

Tests are corrected **per target variable**, not globally. Reason: when a user picks "Squat 1RM" as their target, they're effectively running one family of tests (all factors against that target). Correcting across unrelated targets (bench press factors mixed with squat factors) would be overly conservative.

So: for each target, collect all factor × lag p-values, apply BH within that group, then store the adjusted p-values.

---

## 4. Time Lag Handling

### 4.1 Lag Range

For each target-factor pair, the engine tests lags 0 through 7 days:
- Lag 0: factor and target on the same day
- Lag 1: factor from yesterday, target today
- Lag 2: factor from 2 days ago, target today
- ...up to lag 7

### 4.2 Selecting the Best Lag

For each target-factor pair, the engine picks the lag with the **smallest adjusted p-value** (strongest significance). If multiple lags are significant, only the best one is stored as the primary result. The user can optionally switch between significant lags in the Explore UI.

### 4.3 Autocorrelation Problem

Many lifestyle variables are autocorrelated (e.g., if someone sleeps 8h on Monday, they likely sleep ~8h on Tuesday). This means a "lag 2" result might just be reflecting lag 0 via autocorrelation, not a genuine delayed effect.

**Mitigation:**
- When multiple lags are significant for the same pair, compute the **partial correlation** of each lag controlling for adjacent lags
- Only report a non-zero lag as the "best" if it remains significant after controlling for lag 0
- In the insight card, only claim "sleep 2 nights before affects performance" if the lag-2 effect is independently significant beyond what lag-0 already explains
- If all lag significance is explained by autocorrelation in the factor, collapse to lag 0

### 4.4 Irregular Training Schedules

Users don't train every day. When computing lagged correlations:
- The target variable (training performance) only exists on training days
- The factor variable (sleep, nutrition) may exist on non-training days
- Lag is computed as **calendar days**, not "training sessions ago"
- Example: if a user trains Monday and Thursday, the lag-1 factor for Thursday's session is Wednesday's sleep, not Monday's

Days where the target is missing (rest days) are simply excluded from the analysis. The `sample_size` reflects only days where both target and factor had values.

---

## 5. Data Completeness & Sparse Data Handling

### 5.1 Completeness Tracking

For each target-factor pair, the engine computes a **data completeness ratio**:
```
completeness = days_with_both_values / total_days_in_analysis_window
```

This is stored in `correlation_results.data_completeness`.

### 5.2 Minimum Thresholds

- **Absolute minimum:** n ≥ 20 matched data points (days where both target and factor have values). Below this, the pair is excluded entirely.
- **Completeness warning:** if completeness < 0.5 (the pair only has data for less than half the analysis window), the result is still shown if significant, but the confidence badge is capped at "Early trend" regardless of effect size, and a note is appended: *"Based on limited data — you logged [factor] on X% of training days."*

### 5.3 HealthKit Data Gaps

HealthKit variables (sleep, steps, HRV, resting HR) are often missing if the user doesn't wear their watch consistently. The engine:
- Does NOT impute missing values (no gap-filling with averages or interpolation)
- Simply excludes days with missing data from the analysis
- Tracks completeness separately for HealthKit variables to surface the warning above
- If a HealthKit variable has < 20 matched data points across the entire history, it doesn't appear as an available factor at all

---

## 6. Confidence Badge Thresholds

The badge shown to the user is determined by a matrix of **effect size** and **sample size**:

| | n ≥ 100 | 50 ≤ n < 100 | 20 ≤ n < 50 |
|---|---------|-------------|-------------|
| **Large effect** | Strong | Strong | Moderate |
| **Medium effect** | Strong | Moderate | Early trend |
| **Small effect** | Moderate | Early trend | Early trend |

Where effect size thresholds are defined per test (see section 2.1).

Additionally:
- If `data_completeness < 0.5`, cap at "Early trend" regardless of the above
- If the result only became significant in the most recent recomputation (was not significant before), cap at "Early trend" for one cycle to avoid showing unstable results as strong findings

---

## 7. "What Matters Most" — Partial Correlation

### 7.1 Method

When showing the ranked summary of all significant factors for a target:

1. Collect all factors that passed significance for this target (from pairwise analysis)
2. Build a matrix of target + all significant factors (using each factor's best lag)
3. Compute **Spearman partial correlations**: for each factor, compute its correlation with the target after removing the linear effect of all other factors
4. Re-test significance of each partial correlation
5. Rank by |partial ρ|

### 7.2 Handling Multicollinearity

If factors are highly intercorrelated (e.g., sleep, energy, and mood all moving together):
- Compute the **condition number** of the factor correlation matrix
- If condition number > 30 (indicating severe multicollinearity), fall back to **semi-partial correlations** (only remove variance from the other factors in the factor variable, not the target)
- If that's still unstable, fall back to simply ranking by pairwise effect size and appending a note: *"Some of these factors are closely related to each other, so their individual rankings are approximate."*

### 7.3 Dimmed Factors

A factor that was significant in pairwise analysis but becomes insignificant (adjusted p ≥ 0.05) after partial correlation appears dimmed with: *"This may be explained by other factors."*

This means its apparent relationship with the target is largely accounted for by other variables. Example: "Mood" might correlate with squat performance, but once you account for sleep and stress, mood's unique contribution disappears.

---

## 8. Pre-Computation Schedule

### 8.1 When to Recompute

- **Full recomputation:** weekly (e.g., Sunday night or on first app open of the week). Recomputes all pairwise tests for all targets.
- **Incremental update:** on each app open, if new data has been logged since last computation, recompute only the targets/factors that have new data points.
- **On-demand:** when the user opens Explore, check if results are stale (> 7 days) and trigger recomputation if needed.

### 8.2 Performance Budget

Target: full recomputation completes in < 10 seconds for a user with 1 year of daily data (~365 training days, ~30 exercises, ~40 factors).

Estimation:
- ~30 exercises × 40 factors × 8 lags = ~9,600 Spearman correlations
- Spearman on n=200 data points: ~0.1ms each (Accelerate vDSP)
- Raw computation: ~1 second
- BH correction + bucket comparisons + storage: ~2 seconds
- Total: ~3 seconds (well within budget)

Partial correlations for "What Matters Most" are computed on-demand when the user views that section, not pre-computed.

### 8.3 Storage

Results are stored in the `correlation_results` SwiftData table (on-device only). On each recomputation:
- Delete all previous results for the user
- Insert fresh results
- This avoids stale data accumulation and simplifies the model (no diffing/updating)

---

## 9. Insight Card Generation

### 9.1 Pre-Built Card Templates

Each insight card is generated from a template + computed data. Templates define:
- The target-factor pair to check
- The sentence template with placeholders (e.g., "You lift {pct_diff}% more volume when you sleep over {threshold} hours")
- The category (Sleep & Recovery, Nutrition, Lifestyle, Body Composition)

### 9.2 Threshold Detection

For continuous factors, the engine finds the optimal split point (not just the median) by testing multiple thresholds and picking the one that maximizes the mean difference between groups, subject to both groups having n ≥ 10.

Example: for sleep, test splits at 5h, 5.5h, 6h, 6.5h, 7h, 7.5h, 8h. The split that produces the largest significant difference in performance becomes the threshold in the insight: "You lift X% more when you sleep over **7 hours**."

### 9.3 Card Ranking

Cards are ranked for display by: `|effect_size| × log(sample_size)`

This balances practical significance (large effect) with statistical reliability (more data). A moderate effect based on 200 data points ranks higher than a large effect based on 25 data points.

### 9.4 Card Refresh and Stability

To avoid cards flickering in and out:
- A card must be significant for **2 consecutive computation cycles** before appearing
- A card must be insignificant for **2 consecutive cycles** before disappearing
- This adds ~2 weeks of hysteresis, preventing unstable borderline results from confusing the user

---

## 10. Edge Cases

### 10.1 Not Enough Exercises

If a user only does 2–3 exercises, the per-exercise targets are limited. The engine should still generate useful insights from aggregate targets (total volume, average RPE, session duration).

### 10.2 Identical Values

If a factor has zero variance (e.g., user always sleeps exactly 7h), correlation is undefined. The engine skips this pair and does not include it in the multiple comparison correction count.

### 10.3 Extreme Outliers

Before computing correlations, the engine applies a light outlier filter:
- For continuous variables, flag values beyond 3 standard deviations from the mean
- Do NOT remove outliers automatically — they may be real (e.g., a massive PR, or a terrible night of sleep)
- Instead, run the analysis twice: with and without outliers. If the result changes significance, append a note to the insight: *"This finding is sensitive to a few unusual data points."*

### 10.4 User Changes Unit System

Since all data is stored in metric (see DATA_MODEL.md conventions), switching unit systems has no effect on computation. Only display changes.

### 10.5 User Deletes Historical Data

If a user deletes old workouts or daily logs, the next recomputation will reflect the reduced dataset. Some insights may disappear if they drop below n ≥ 20. This is expected and correct.

### 10.6 Seasonal Effects

The engine does not currently correct for seasonality (e.g., users might train harder in winter). This is noted as a known limitation. A future enhancement could add month/season as a control variable.
