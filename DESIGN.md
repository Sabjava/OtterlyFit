# FitCard – Design & Implementation Plan

## Goal

Enable users to scan physical fitness cards, automatically recognize exercises, build reusable workout routines, play guided workouts with voice instructions and timers, record completed workouts, and optionally sync results to Apple Health.

Offline-first. No backend required for MVP.

### Implementation Plan Summary (Step 1.1)

| Deliverable | Section |
|---|---|
| Milestones | [Implementation Milestones](#implementation-milestones) (M1–M14) |
| Feature boundaries | [Feature Boundaries](#feature-boundaries) |
| MVVM structure | [MVVM Architecture](#mvvm-architecture) + [Project Structure](#project-structure) |
| SwiftData model plan | [SwiftData Models](#swiftdata-models) |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Architecture | MVVM (feature-first) |
| Persistence | SwiftData |
| OCR | Vision + VisionKit |
| Voice | AVSpeechSynthesizer |
| Health | HealthKit |
| Charts | Swift Charts |

---

## Core Features

### 1. Exercise Card Library
- Capture card image via camera
- OCR extracts text; Vision identifies the card
- Match to existing exercise or create new
- Store card image and extracted attributes

### 2. Exercise Database
- CRUD operations
- Search by name, muscle, equipment, favorites, recently used

### 3. Workout Routine Builder
- Create reusable routines with ordered exercise blocks
- Configure sets, reps, duration, rest intervals, weight, notes
- Reorder, duplicate, delete blocks

### 4. Workout Player
- Guided playback with card image, timers, progress ring
- Voice prompts (preparation, begin, rep count, rest, next exercise, complete)
- Pause, skip, finish controls

### 5. Workout Summary
- Duration, active/rest time, sets, reps, calories, completion %
- Save, share, repeat, edit routine

### 6. Workout History
- Daily, weekly, monthly views
- Streak, favorite exercise, time trained, muscle distribution

### 7. Apple Health
- Save workout with start/end time, duration, calories
- Future: read heart rate, active energy, recovery

---

## Feature Boundaries

Each feature is a self-contained module. Features communicate only through shared **Models**, **Repositories**, and **Services** — never by importing another feature's View or ViewModel.

### Boundary Rules

| Rule | Detail |
|---|---|
| **One feature per step** | Implement exactly one feature boundary per implementation pass (see `STEPS.md`). |
| **No cross-feature View imports** | `RoutineBuilder` must not import `Scanner/CardScannerView`. Navigate via `AppRouter` or coordinator. |
| **Shared data via repositories** | Features read/write through `ExerciseRepository`, `RoutineRepository`, `WorkoutRepository`. |
| **Platform APIs via services** | Vision, HealthKit, speech, and haptics live in `Services/`; features never call them directly. |
| **Player is isolated** | `WorkoutPlayer` owns playback state; it receives a `Routine` snapshot at start and returns a `Workout` result at finish. |

### Feature Map

| Feature | Scope (owns) | Does NOT own | Depends on | STEPS.md Phase |
|---|---|---|---|---|
| **Home** | Dashboard, navigation entry points | Business logic for child features | `AppRouter` only | — |
| **Scanner** | Camera UI, OCR flow, exercise confirm screen | Exercise library list, routine logic | `CardScannerService`, `ExerciseRecognitionService`, `ExerciseRepository` | Phase 3 |
| **ExerciseLibrary** | List, search, filter, detail, edit, delete | Scanning, routine composition | `ExerciseRepository` | Phase 4 |
| **RoutineBuilder** | Routine list, builder, block config, reorder | Workout playback, history | `RoutineRepository`, `ExerciseRepository` | Phase 5 |
| **WorkoutPlayer** | State machine, timers, player UI, voice, haptics | Persisting workout, summary display | `WorkoutPlayerService`, `VoicePromptService`, `HapticService`, `TimerEngine` | Phase 6 |
| **WorkoutSummary** | Post-workout stats display, save/share/repeat actions | Player state, history list | `WorkoutRepository`, `CalorieEstimator`, `HealthKitService` | Phase 7 |
| **History** | Past workouts, calendar grouping, detail view | Live playback | `WorkoutRepository`, `StatisticsService` | Phase 8 |
| **Settings** | User preferences (units, voice, haptics) | Feature-specific config | `UserDefaults` or SwiftData settings model | Phase 10 |

### Shared Layers (not features)

| Layer | Used by | Boundary |
|---|---|---|
| **Models** | All features | Pure data; no imports from Features or Services |
| **Persistence** | Repositories only | `ModelContainer` setup; not accessed from Views |
| **Repositories** | Feature ViewModels | CRUD + queries; no UI, no platform APIs |
| **Services** | Feature ViewModels | Platform side-effects; no SwiftUI |
| **Utilities** | Services + ViewModels | Stateless helpers (`TimerEngine`, `CalorieEstimator`) |
| **Core** | All layers | Extensions, protocols, constants |

### Data Flow Across Features

```
Scanner ──creates──▶ Exercise ──referenced by──▶ RoutineBuilder
                                                      │
                                                      ▼
                                              Routine (snapshot)
                                                      │
                                                      ▼
                                              WorkoutPlayer
                                                      │
                                                      ▼
                                              Workout result
                                                      │
                                    ┌─────────────────┴─────────────────┐
                                    ▼                                   ▼
                            WorkoutSummary                          History
                                    │
                                    ▼
                              HealthKit (optional)
```

### Parallel Implementation Tracks

After M3 (Repositories), these tracks are independent:

| Track | Features | Steps |
|---|---|---|
| **A — Content** | Scanner → ExerciseLibrary | STEPS 5–8 |
| **B — Routines** | RoutineBuilder | STEPS 9 |
| **C — Playback** | WorkoutPlayer → WorkoutSummary | STEPS 10–17 |
| **D — Analytics** | History + Statistics | STEPS 18–20 |
| **E — Health** | HealthKit | STEPS 21–22 |
| **F — Polish** | Settings, Onboarding | STEPS 23–24 |

Tracks A and B merge before Track C. Track C must complete before D and E.

---

## Project Structure

Feature-first MVVM. Each feature owns its Views and ViewModels; shared code lives in Core.

```
FitCard/
├── App/
│   ├── FitCardApp.swift              # @main, ModelContainer setup
│   └── AppRouter.swift               # Tab/navigation root
│
├── Core/
│   ├── Extensions/                   # Date, String, View helpers
│   ├── Protocols/                    # RepositoryProtocol, ServiceProtocol
│   └── Constants/                    # App-wide enums, defaults
│
├── Models/
│   ├── Exercise.swift
│   ├── Routine.swift
│   ├── RoutineExercise.swift
│   ├── Workout.swift
│   ├── WorkoutExercise.swift
│   └── Enums/
│       ├── ExerciseCategory.swift
│       ├── MuscleGroup.swift
│       ├── Equipment.swift
│       └── Difficulty.swift
│
├── Persistence/
│   ├── ModelContainer+Setup.swift    # Schema, migrations, preview container
│   └── PreviewData.swift             # Sample data for SwiftUI previews
│
├── Services/
│   ├── ExerciseRepository.swift
│   ├── RoutineRepository.swift
│   ├── WorkoutRepository.swift
│   ├── CardScannerService.swift      # VisionKit camera + OCR
│   ├── ExerciseRecognitionService.swift
│   ├── WorkoutPlayerService.swift    # State machine, timers
│   ├── VoicePromptService.swift      # AVSpeechSynthesizer
│   ├── HapticService.swift
│   ├── HealthKitService.swift
│   └── StatisticsService.swift       # Aggregations for charts
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   │
│   ├── Scanner/
│   │   ├── CardScannerView.swift
│   │   ├── CardScannerViewModel.swift
│   │   └── ExerciseConfirmView.swift
│   │
│   ├── ExerciseLibrary/
│   │   ├── ExerciseListView.swift
│   │   ├── ExerciseListViewModel.swift
│   │   ├── ExerciseDetailView.swift
│   │   └── ExerciseEditView.swift
│   │
│   ├── RoutineBuilder/
│   │   ├── RoutineListView.swift
│   │   ├── RoutineListViewModel.swift
│   │   ├── RoutineBuilderView.swift
│   │   ├── RoutineBuilderViewModel.swift
│   │   └── ExerciseBlockConfigView.swift
│   │
│   ├── WorkoutPlayer/
│   │   ├── WorkoutPlayerView.swift
│   │   ├── WorkoutPlayerViewModel.swift
│   │   ├── WorkoutPlayerState.swift  # State machine enum
│   │   └── Components/
│   │       ├── ProgressRingView.swift
│   │       ├── CountdownView.swift
│   │       └── ExerciseCardView.swift
│   │
│   ├── WorkoutSummary/
│   │   ├── WorkoutSummaryView.swift
│   │   └── WorkoutSummaryViewModel.swift
│   │
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── HistoryViewModel.swift
│   │   ├── WorkoutDetailView.swift
│   │   └── StatisticsDashboardView.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── Utilities/
│   ├── TimerEngine.swift             # Reusable async countdown timer
│   └── CalorieEstimator.swift
│
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

---

## SwiftData Models

### Enums

```swift
enum ExerciseCategory: String, Codable, CaseIterable { case strength, cardio, flexibility, balance, other }
enum MuscleGroup: String, Codable, CaseIterable { case chest, back, shoulders, arms, core, legs, fullBody, other }
enum Equipment: String, Codable, CaseIterable { case none, dumbbell, barbell, kettlebell, band, machine, bodyweight, other }
enum Difficulty: String, Codable, CaseIterable { case beginner, intermediate, advanced }
```

### Exercise

| Property | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| name | String | Required |
| category | ExerciseCategory | |
| muscleGroups | [MuscleGroup] | Stored as raw-value array |
| equipment | Equipment | |
| difficulty | Difficulty | |
| cardImageData | Data? | JPEG of scanned card |
| exerciseDescription | String | Avoid `description` (NSObject conflict) |
| instructions | String | |
| tips | String | |
| isFavorite | Bool | Default false |
| createdAt | Date | |
| lastUsedAt | Date? | For "recently used" sort |

**Relationships:** `routineExercises` → [RoutineExercise], `workoutExercises` → [WorkoutExercise]

### Routine

| Property | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| name | String | Required |
| routineDescription | String | |
| category | ExerciseCategory | |
| estimatedDuration | Int | Seconds |
| isFavorite | Bool | Default false |
| createdAt | Date | |
| updatedAt | Date | |

**Relationships:** `exercises` → [RoutineExercise] (cascade delete), `workouts` → [Workout]

### RoutineExercise (join + config)

| Property | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| order | Int | Sort index within routine |
| sets | Int | Default 3 |
| repetitions | Int | Default 10 |
| secondsPerRep | Int | Hold/rep duration in seconds |
| restBetweenReps | Int | Seconds, optional (0 = none) |
| restBetweenSets | Int | Seconds |
| weight | Double? | Optional kg/lbs |
| notes | String | |

**Relationships:** `routine` → Routine, `exercise` → Exercise

### Workout

| Property | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| date | Date | Workout day |
| startTime | Date | |
| endTime | Date? | Set on completion |
| duration | Int | Total seconds |
| activeTime | Int | Seconds excluding rest |
| restTime | Int | Seconds |
| calories | Double | Estimated |
| isCompleted | Bool | |
| notes | String | |
| completionPercentage | Double | 0.0–1.0 |

**Relationships:** `routine` → Routine?, `exercises` → [WorkoutExercise] (cascade delete)

### WorkoutExercise (snapshot)

| Property | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| completedSets | Int | |
| completedRepetitions | Int | Total reps across sets |
| actualDuration | Int | Seconds |
| order | Int | Preserved from routine |

**Relationships:** `workout` → Workout, `exercise` → Exercise

### Entity Relationship Diagram

```
Exercise ──< RoutineExercise >── Routine ──< Workout
    │                                    │
    └──< WorkoutExercise >──────────────┘
```

---

## MVVM Architecture

### Layer Responsibilities

| Layer | Responsibility | Rules |
|---|---|---|
| **View** | SwiftUI layout, bindings, navigation | No business logic. Observes ViewModel via `@Observable` or `@StateObject`. |
| **ViewModel** | UI state, user actions, coordinates services | `@MainActor`, `@Observable`. Calls services via `async/await`. No direct SwiftData queries in Views. |
| **Service** | Platform APIs, algorithms, side effects | Stateless where possible. Injected into ViewModels. |
| **Repository** | SwiftData CRUD, queries, sorting | Single source of truth for persistence. Returns model objects. |
| **Model** | SwiftData `@Model` classes + enums | No UI or service dependencies. |

### Data Flow

```
View → ViewModel → Repository → SwiftData
                 → Service    → Vision / HealthKit / AVSpeech
```

### Dependency Injection

- `ModelContainer` created in `FitCardApp` and injected via `.environment(\.modelContext)` and custom `@Environment` keys for services.
- Repositories receive `ModelContext` (or `ModelContainer`) at init.
- ViewModels receive repositories and services via initializer (testable).

### Concurrency

- All repository and service methods use `async/await`.
- ViewModels are `@MainActor`; background work uses `Task { }` with results published on main actor.
- `TimerEngine` uses `AsyncStream` or `Task.sleep` for countdown ticks.

---

## Services

| Service | Responsibility | Key Methods |
|---|---|---|
| **ExerciseRepository** | Exercise CRUD + search/filter | `fetchAll()`, `search(query:)`, `filter(muscle:equipment:)`, `create()`, `update()`, `delete()`, `markUsed()` |
| **RoutineRepository** | Routine CRUD + block management | `fetchAll()`, `create()`, `addExercise()`, `reorder()`, `duplicateBlock()`, `removeBlock()`, `delete()` |
| **WorkoutRepository** | Workout persistence + history queries | `save()`, `fetchHistory(period:)`, `fetchDetail()`, `delete()` |
| **CardScannerService** | Camera capture + OCR | `scanCard() async -> ScanResult` (image + recognized text) |
| **ExerciseRecognitionService** | Match OCR text to existing exercise | `recognize(text:image:) async -> RecognitionResult` (match or new) |
| **WorkoutPlayerService** | Playback state machine + timer orchestration | `start()`, `pause()`, `skip()`, `finish()`, publishes `PlayerState` |
| **VoicePromptService** | Spoken cues | `speak(_ text:)`, queue management, interrupt on skip |
| **HapticService** | Rest-timer vibration | `restStart()`, `restEnd()`, `repComplete()` |
| **HealthKitService** | Write workouts to Apple Health | `requestAuthorization()`, `saveWorkout()` |
| **StatisticsService** | Aggregate history for charts | `streak()`, `totalWorkouts()`, `muscleDistribution()`, `favoriteExercise()` |
| **TimerEngine** | Reusable countdown | `countdown(from: Int) -> AsyncStream<Int>` |
| **CalorieEstimator** | Estimate calories from duration + exercise metadata | `estimate(activeSeconds:exercises:)` |

### Workout Player State Machine

```
idle → preparing(countdown: 3) → exercising(set, rep, timer)
     → resting(setRest | repRest) → nextExercise
     → completed → summary
```

Transitions: `start`, `tick`, `repComplete`, `setComplete`, `restComplete`, `pause`, `resume`, `skip`, `finish`.

---

## Screens

| # | Screen | Feature Module |
|---|---|---|
| 1 | Home (start, scan, history, routines, cards) | Home |
| 2 | Card Scanner (camera, recognize, save) | Scanner |
| 3 | Exercise Library (search, filter, edit) | ExerciseLibrary |
| 4 | Routine Builder (drag-drop, configure blocks) | RoutineBuilder |
| 5 | Workout Player (card, timer, voice, progress) | WorkoutPlayer |
| 6 | Workout Summary (stats, save, Health) | WorkoutSummary |
| 7 | History (calendar, details, statistics) | History |
| 8 | Settings | Settings |

---

## Implementation Milestones

### M1 — Project Foundation
- Create Xcode project (iOS 17+, SwiftUI lifecycle)
- Scaffold folder structure with placeholder files
- Configure SwiftData `ModelContainer` in app entry
- Set up `AppRouter` with tab navigation shell

**Deliverable:** Empty app launches with tab bar, no business logic.

---

### M2 — SwiftData Models & Persistence
- Implement all `@Model` classes and enums
- Define relationships with cascade delete rules
- Create `PreviewData` with sample exercises, routines, workouts
- Configure `ModelContainer+Setup` with schema

**Deliverable:** Models compile; preview data loads in Xcode previews.

---

### M3 — Repositories
- Implement `ExerciseRepository`, `RoutineRepository`, `WorkoutRepository`
- CRUD, search, filter, sort, reorder operations
- All methods `async/await`

**Deliverable:** Repositories tested via preview/debug harness (no UI).

---

### M4 — Card Scanner
- `CardScannerService`: VisionKit camera capture + Vision OCR
- Return `ScanResult` (image data + recognized text)
- Scanner UI with live camera preview

**Deliverable:** User can scan a card and see extracted text. No database save yet.

---

### M5 — Exercise Recognition & Save
- `ExerciseRecognitionService`: fuzzy match OCR text against existing exercises
- Create new `Exercise` if no match
- Confirm/edit screen before save
- Wire to `ExerciseRepository`

**Deliverable:** Scanned card creates or matches an exercise in SwiftData.

---

### M6 — Exercise Library UI
- List with search bar and filter chips (muscle, equipment, favorites)
- Detail view (card image, instructions, tips)
- Edit and delete
- Favorite toggle

**Deliverable:** Full exercise CRUD from UI.

---

### M7 — Routine Builder
- Routine list (create, edit, delete, favorite)
- Builder view: add exercises from library, drag-to-reorder
- Per-block config (sets, reps, seconds, rest, weight, notes)
- Duplicate and delete blocks
- Estimated duration calculation

**Deliverable:** User can create and edit complete routines.

---

### M8 — Workout Player (Core)
- `WorkoutPlayerState` enum and state machine
- `TimerEngine` with async countdown
- `WorkoutPlayerViewModel`: preparation → exercise → rest → next cycle
- Player UI: card image, progress ring, rep/set counters, pause/skip/finish

**Deliverable:** User can play through a routine with timers (no voice yet).

---

### M9 — Workout Player (Voice & Haptics)
- `VoicePromptService`: spoken cues at each transition
- `HapticService`: vibration during rest countdown
- Integrate into player state machine

**Deliverable:** Fully guided workout experience.

---

### M10 — Save Workout & Summary
- On completion, persist `Workout` + `WorkoutExercise` snapshots
- Summary screen: duration, active/rest, sets, reps, calories, completion %
- Actions: save, share, repeat, edit routine

**Deliverable:** Completed workouts stored in SwiftData with summary UI.

---

### M11 — Workout History
- History list with daily / weekly / monthly grouping
- Workout detail view
- Delete workout

**Deliverable:** User can browse past workouts.

---

### M12 — Statistics Dashboard
- `StatisticsService` aggregations
- Swift Charts: streak, total workouts, time trained, muscle distribution, favorite exercise

**Deliverable:** Statistics tab with charts.

---

### M13 — Apple Health Integration
- `HealthKitService`: request authorization, write workout
- Trigger from summary screen save action

**Deliverable:** Completed workouts appear in Apple Health.

---

### M14 — Polish
- Settings screen (units, voice on/off, haptics on/off)
- Onboarding flow (permissions, first scan)
- Accessibility (VoiceOver labels, Dynamic Type)
- Architecture review and cleanup

**Deliverable:** Production-ready MVP.

---

## Milestone Dependency Graph

```
M1 → M2 → M3 ─┬→ M4 → M5 → M6 ─┐
               │                 ├→ M7 → M8 → M9 → M10 → M11 → M12
               │                 │                              │
               └─────────────────┘                              ├→ M13
                                                                └→ M14
```

M4–M6 (Scanner + Library) and M7 (Routines) can proceed in parallel after M3.

---

## Future Enhancements

- Apple Watch companion
- Live Activities / Dynamic Island timer
- Siri Shortcuts
- CloudKit sync
- AI card layout recognition
- Voice control ("Next", "Pause", "Skip")
- Interval workout templates
- Progress photos
- Export to CSV/PDF
- Smart routine recommendations

---

## Implementation Rules

See `CURSOR_RULES.md`. Key constraints:

- Read this document before implementing
- One feature per implementation pass
- Preserve MVVM; use SwiftData; use async/await
- Do not modify unrelated files
- Update this document only if architecture changes
- Return only changed files; never regenerate existing code
