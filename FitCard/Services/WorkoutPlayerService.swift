import Foundation

@MainActor
@Observable
final class WorkoutPlayerService {
    private(set) var state: WorkoutPlayerState = .idle
    private(set) var blocks: [WorkoutPlayerBlock] = []

    func load(routine: Routine) {
        blocks = routine.exercises
            .sorted { $0.order < $1.order }
            .map(WorkoutPlayerBlock.init)
        state = .idle
    }

    func start() {
        guard !blocks.isEmpty else { return }
        state = .preparing(countdown: 3)
    }

    func tick() {
        switch state {
        case .preparing(let countdown):
            if countdown > 1 {
                state = .preparing(countdown: countdown - 1)
            } else {
                beginExercise(at: 0)
            }

        case .exerciseStart(let exerciseIndex, let timer):
            if timer > 1 {
                state = .exerciseStart(exerciseIndex: exerciseIndex, timer: timer - 1)
            } else {
                beginSet(exerciseIndex: exerciseIndex, set: 1)
            }

        case .setStart(let exerciseIndex, let set, let timer):
            if timer > 1 {
                state = .setStart(exerciseIndex: exerciseIndex, set: set, timer: timer - 1)
            } else {
                beginRep(exerciseIndex: exerciseIndex, set: set, rep: 1)
            }

        case .exercising(let exerciseIndex, let set, let rep, let timer):
            if timer > 1 {
                state = .exercising(exerciseIndex: exerciseIndex, set: set, rep: rep, timer: timer - 1)
            } else {
                advanceAfterRep(exerciseIndex: exerciseIndex, set: set, rep: rep)
            }

        case .resting(let exerciseIndex, let set, let rep, let kind, let timer):
            if timer > 1 {
                state = .resting(
                    exerciseIndex: exerciseIndex,
                    set: set,
                    rep: rep,
                    kind: kind,
                    timer: timer - 1
                )
            } else {
                advanceAfterRest(exerciseIndex: exerciseIndex, set: set, rep: rep, kind: kind)
            }

        default:
            break
        }
    }

    func restComplete() {
        guard case .resting(let exerciseIndex, let set, let rep, let kind, _) = state else { return }
        advanceAfterRest(exerciseIndex: exerciseIndex, set: set, rep: rep, kind: kind)
    }

    func nextSet() {
        switch state {
        case .exercising(let exerciseIndex, let set, _, _),
             .setStart(let exerciseIndex, let set, _),
             .resting(let exerciseIndex, let set, _, _, _):
            skipToNextSet(exerciseIndex: exerciseIndex, set: set)

        default:
            break
        }
    }

    func nextExercise() {
        guard let exerciseIndex = state.exerciseIndex, blocks.indices.contains(exerciseIndex) else { return }
        let nextIndex = exerciseIndex + 1
        if blocks.indices.contains(nextIndex) {
            beginExercise(at: nextIndex)
        } else {
            state = .completed
        }
    }

    func pause() {
        guard state.isActive else { return }
        if case .paused = state { return }
        state = .paused(PausedSnapshot(state: state))
    }

    func resume() {
        guard case .paused(let snapshot) = state else { return }
        state = snapshot.state
    }

    func finish() {
        state = .completed
    }

    private func beginExercise(at index: Int) {
        guard blocks.indices.contains(index) else {
            state = .completed
            return
        }
        state = .exerciseStart(
            exerciseIndex: index,
            timer: AppConstants.exerciseIntroDuration
        )
    }

    private func beginSet(exerciseIndex: Int, set: Int) {
        guard blocks.indices.contains(exerciseIndex) else {
            state = .completed
            return
        }

        if set >= 2 {
            state = .setStart(
                exerciseIndex: exerciseIndex,
                set: set,
                timer: AppConstants.setIntroDuration
            )
        } else {
            beginRep(exerciseIndex: exerciseIndex, set: set, rep: 1)
        }
    }

    private func beginRep(exerciseIndex: Int, set: Int, rep: Int) {
        guard blocks.indices.contains(exerciseIndex) else {
            state = .completed
            return
        }

        let block = blocks[exerciseIndex]
        state = .exercising(
            exerciseIndex: exerciseIndex,
            set: set,
            rep: rep,
            timer: max(block.secondsPerRep, 1)
        )
    }

    private func advanceAfterRep(exerciseIndex: Int, set: Int, rep: Int) {
        guard blocks.indices.contains(exerciseIndex) else {
            state = .completed
            return
        }

        let block = blocks[exerciseIndex]

        if rep < block.repetitions {
            if block.restBetweenReps > 0 {
                state = .resting(
                    exerciseIndex: exerciseIndex,
                    set: set,
                    rep: rep,
                    kind: .repRest,
                    timer: block.restBetweenReps
                )
            } else {
                state = .exercising(
                    exerciseIndex: exerciseIndex,
                    set: set,
                    rep: rep + 1,
                    timer: max(block.secondsPerRep, 1)
                )
            }
            return
        }

        advanceAfterSet(exerciseIndex: exerciseIndex, set: set)
    }

    private func skipToNextSet(exerciseIndex: Int, set: Int) {
        guard blocks.indices.contains(exerciseIndex) else {
            state = .completed
            return
        }

        let block = blocks[exerciseIndex]
        guard set < block.sets else { return }

        beginSet(exerciseIndex: exerciseIndex, set: set + 1)
    }

    private func advanceAfterSet(exerciseIndex: Int, set: Int) {
        guard blocks.indices.contains(exerciseIndex) else {
            state = .completed
            return
        }

        let block = blocks[exerciseIndex]

        if set < block.sets {
            if block.restBetweenSets > 0 {
                state = .resting(
                    exerciseIndex: exerciseIndex,
                    set: set,
                    rep: block.repetitions,
                    kind: .setRest,
                    timer: block.restBetweenSets
                )
            } else {
                beginSet(exerciseIndex: exerciseIndex, set: set + 1)
            }
            return
        }

        let nextIndex = exerciseIndex + 1
        if blocks.indices.contains(nextIndex) {
            let rest = AppConstants.defaultRestBetweenExercises
            if rest > 0 {
                state = .resting(
                    exerciseIndex: exerciseIndex,
                    set: block.sets,
                    rep: block.repetitions,
                    kind: .exerciseRest,
                    timer: rest
                )
            } else {
                beginExercise(at: nextIndex)
            }
        } else {
            state = .completed
        }
    }

    private func advanceAfterRest(exerciseIndex: Int, set: Int, rep: Int, kind: RestKind) {
        guard blocks.indices.contains(exerciseIndex) else {
            state = .completed
            return
        }

        let block = blocks[exerciseIndex]

        switch kind {
        case .repRest:
            state = .exercising(
                exerciseIndex: exerciseIndex,
                set: set,
                rep: rep + 1,
                timer: max(block.secondsPerRep, 1)
            )
        case .setRest:
            beginSet(exerciseIndex: exerciseIndex, set: set + 1)
        case .exerciseRest:
            beginExercise(at: exerciseIndex + 1)
        }
    }
}
