# Implementation Steps

## Phase 1 — Foundation

1. Review [DESIGN.md](http://DESIGN.md). Create an implementation plan:

   - milestones

   - feature boundaries

   - MVVM structure

   - SwiftData model plan

2. Create feature-based project structure.

   Add folders and placeholder files only.

---

## Phase 2 — Data Layer

3. Implement SwiftData models:

   - Exercise

   - Routine

   - RoutineExercise

   - Workout

   - WorkoutExercise

4. Add repositories/services for CRUD operations.

---

## Phase 3 — Card Scanner

5. Implement card scanning using VisionKit.

6. Add OCR text extraction using Vision.

7. Create exercise recognition flow:

   - match existing exercise

   - create new exercise if missing

   - save card image and metadata

---

## Phase 4 — Exercise Library

8. Build exercise library UI:

   - search

   - filter

   - details

   - edit/delete

---

## Phase 5 — Routine Builder

9. Build routine creation:

   - add exercises

   - reorder exercises

   - configure sets

   - configure repetitions

   - configure timing/rest

---

## Phase 6 — Workout Player

10. Design workout state machine:

    - exercise

    - repetition

    - rest

    - completion states

11. Implement WorkoutPlayer ViewModel.

12. Implement timers:

    - repetition timer

    - rest timer

    - set progression

13. Build workout player UI:

    - exercise card

    - current set

    - repetition counter

    - timer

    - progress

14. Add voice guidance with AVSpeechSynthesizer.

15. Add haptic feedback.

---

## Phase 7 — Workout Recording

16. Save completed workouts.

17. Store:

    - duration

    - sets

    - repetitions

    - exercises

    - timestamps

---

## Phase 8 — History & Analytics

18. Build workout history.

19. Add statistics:

    - frequency

    - duration

    - exercise usage

    - trends

20. Add charts using Swift Charts.

---

## Phase 9 — Health Integration

21. Add HealthKit permissions.

22. Export completed workouts to Apple Health.

---

## Phase 10 — Product Polish

23. Add:

    - onboarding

    - settings

    - accessibility

    - error handling

24. Final architecture review:

    - performance

    - code quality

    - consistency with [DESIGN.md](http://DESIGN.md)