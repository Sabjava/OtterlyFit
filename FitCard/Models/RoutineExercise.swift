import Foundation
import SwiftData

@Model
final class RoutineExercise {
    var id: UUID
    var order: Int
    var sets: Int
    var repetitions: Int
    var secondsPerRep: Int
    var restBetweenReps: Int
    var restBetweenSets: Int
    var weight: Double?
    var notes: String

    var routine: Routine?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        sets: Int = 3,
        repetitions: Int = 10,
        secondsPerRep: Int = 2,
        restBetweenReps: Int = 0,
        restBetweenSets: Int = AppConstants.defaultRestBetweenSets,
        weight: Double? = nil,
        notes: String = "",
        routine: Routine? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.sets = sets
        self.repetitions = repetitions
        self.secondsPerRep = secondsPerRep
        self.restBetweenReps = restBetweenReps
        self.restBetweenSets = restBetweenSets
        self.weight = weight
        self.notes = notes
        self.routine = routine
        self.exercise = exercise
    }
}
