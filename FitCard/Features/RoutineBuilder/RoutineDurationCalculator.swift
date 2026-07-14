import Foundation
import SwiftData

enum RoutineDurationCalculator {
    static func estimatedDuration(for blocks: [RoutineExercise]) -> Int {
        let workDuration = blocks.reduce(0) { total, block in
            total + duration(for: block)
        }
        let exerciseRest = max(0, blocks.count - 1) * AppConstants.defaultRestBetweenExercises
        return workDuration + exerciseRest
    }

    static func duration(for block: RoutineExercise) -> Int {
        let repDuration = block.repetitions * block.secondsPerRep
        let repRest = max(0, block.repetitions - 1) * block.restBetweenReps
        let workPerSet = repDuration + repRest
        let setRest = max(0, block.sets - 1) * block.restBetweenSets
        return block.sets * workPerSet + setRest
    }

    static func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes == 0 { return "\(remainingSeconds)s" }
        if remainingSeconds == 0 { return "\(minutes)m" }
        return "\(minutes)m \(remainingSeconds)s"
    }
}
