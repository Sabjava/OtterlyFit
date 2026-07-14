import Foundation
import SwiftUI

enum RestKind: Equatable {
    case repRest
    case setRest
    case exerciseRest
}

enum WorkoutPlayerState: Equatable {
    case idle
    case preparing(countdown: Int)
    case exerciseStart(exerciseIndex: Int, timer: Int)
    case setStart(exerciseIndex: Int, set: Int, timer: Int)
    case exercising(exerciseIndex: Int, set: Int, rep: Int, timer: Int)
    case resting(exerciseIndex: Int, set: Int, rep: Int, kind: RestKind, timer: Int)
    indirect case paused(PausedSnapshot)
    case completed

    var isActive: Bool {
        switch self {
        case .idle, .completed:
            false
        default:
            true
        }
    }
}

struct PausedSnapshot: Equatable {
    let state: WorkoutPlayerState
}

struct WorkoutPlayerBlock: Identifiable, Equatable {
    let id: UUID
    let exerciseName: String
    let cardImageData: Data?
    let sets: Int
    let repetitions: Int
    let secondsPerRep: Int
    let restBetweenReps: Int
    let restBetweenSets: Int

    init(block: RoutineExercise) {
        id = block.id
        exerciseName = block.exercise?.name ?? "Exercise"
        cardImageData = block.exercise?.cardImageData
        sets = block.sets
        repetitions = block.repetitions
        secondsPerRep = block.secondsPerRep
        restBetweenReps = block.restBetweenReps
        restBetweenSets = block.restBetweenSets
    }
}

enum WorkoutTimerStyle {
    case preparing
    case exerciseStart
    case setStart
    case rest
    case reps

    var ringColor: Color {
        switch self {
        case .preparing, .reps:
            .blue
        case .exerciseStart:
            .red
        case .setStart:
            .orange
        case .rest:
            .green
        }
    }
}

extension WorkoutPlayerState {
    var statusTitle: String {
        switch self {
        case .idle:
            "Ready"
        case .preparing:
            "Get Ready"
        case .exerciseStart:
            "New Exercise"
        case .setStart(_, let set, _):
            "Set \(set)"
        case .exercising:
            "Exercise"
        case .resting:
            "Rest"
        case .paused:
            "Paused"
        case .completed:
            "Complete"
        }
    }

    var countdownValue: Int? {
        switch self {
        case .preparing(let countdown),
             .exerciseStart(_, let countdown),
             .setStart(_, _, let countdown),
             .exercising(_, _, _, let countdown),
             .resting(_, _, _, _, let countdown):
            countdown
        default:
            nil
        }
    }

    var exerciseIndex: Int? {
        switch self {
        case .exercising(let index, _, _, _),
             .resting(let index, _, _, _, _),
             .setStart(let index, _, _),
             .exerciseStart(let index, _):
            index
        default:
            nil
        }
    }

    var setNumber: Int? {
        switch self {
        case .exercising(_, let set, _, _),
             .resting(_, let set, _, _, _),
             .setStart(_, let set, _):
            set
        default:
            nil
        }
    }

    var repNumber: Int? {
        switch self {
        case .exercising(_, _, let rep, _), .resting(_, _, let rep, _, _):
            rep
        default:
            nil
        }
    }

    var timerStyle: WorkoutTimerStyle {
        switch self {
        case .preparing:
            .preparing
        case .exerciseStart:
            .exerciseStart
        case .setStart:
            .setStart
        case .resting:
            .rest
        case .exercising:
            .reps
        default:
            .reps
        }
    }
}
