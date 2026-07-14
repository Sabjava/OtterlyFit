import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    var id: UUID
    var completedSets: Int
    var completedRepetitions: Int
    var actualDuration: Int
    var order: Int

    var workout: Workout?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        completedSets: Int = 0,
        completedRepetitions: Int = 0,
        actualDuration: Int = 0,
        order: Int = 0,
        workout: Workout? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.completedSets = completedSets
        self.completedRepetitions = completedRepetitions
        self.actualDuration = actualDuration
        self.order = order
        self.workout = workout
        self.exercise = exercise
    }
}
