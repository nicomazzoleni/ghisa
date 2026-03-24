# Training Module — Polish & Remaining Work

Tracked list of gaps between the PRD and current implementation. Items are prioritized by user impact.

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Done

---

## High Impact — Core UX

### 1. Exercise History View
- [ ] Per-exercise view showing all logged sets over time
- [ ] Accessible from exercise detail / exercise library
- [ ] Grouped by workout date, showing sets + values

### 2. Personal Records (PRs)
- [ ] Auto-detect PRs per exercise (heaviest weight, most reps at a given weight, estimated 1RM)
- [ ] Display PR badges in exercise history
- [ ] "Recent PRs" surface area (Train tab or exercise detail)

### 3. Set Notes
- [ ] Expose `WorkoutSet.notes` field in SetEntryRow UI
- [ ] Display set notes in workout detail / history views

### 4. Reordering (Drag-and-Drop)
- [ ] Reorder exercises within active workout
- [ ] Reorder sets within an exercise
- [ ] Reorder exercises within routine/template editor

### 5. Superset / Circuit Grouping
- [ ] UI to group exercises together during active workout
- [ ] Visual grouping indicator (bracket, color, indentation)
- [ ] Superset grouping visible in workout history detail
- [ ] Data model already supports this (`supersetGroup: Int?`)

---

## Medium Impact — Quality of Life

### 6. Workout Date/Time Editing
- [ ] Allow user to set date when logging a past workout
- [ ] Allow editing start/end time after the fact

### 7. History Search & Filtering
- [ ] Search by exercise name
- [ ] Filter by date range
- [ ] Filter by flag
- [ ] Filter by muscle group

### 8. Flags Visible in History Rows
- [ ] Show assigned flags (badges) in WorkoutHistoryRow without needing to tap into detail

### 9. Exercise Field Reordering
- [ ] UI to reorder fields in exercise detail/edit view
- [ ] `sortOrder` already exists on the model

### 10. Default Movement Types
- [ ] Pre-populate movement type suggestions (push, pull, hinge, squat, carry, isolation, cardio, other)
- [ ] Currently only suggests from user's existing exercises

---

## Lower Priority

### 11. Workout Location
- [ ] Surface `Workout.location` field in active workout UI (optional input)
- [ ] Display location in workout history detail

### 12. Template Field Targets
- [ ] UI in routine editor to set target values per field (e.g., target weight, target reps)
- [ ] Data model (`WorkoutTemplateFieldTarget`) already exists

### 13. Routine Duplication
- [ ] Allow duplicating a routine to create a variant
