import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    var duration: Int
    var activeTime: Int
    var restTime: Int
    var calories: Double
    var isCompleted: Bool
    var notes: String
    var completionPercentage: Double

    var routine: Routine?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        startTime: Date = .now,
        endTime: Date? = nil,
        duration: Int = 0,
        activeTime: Int = 0,
        restTime: Int = 0,
        calories: Double = 0,
        isCompleted: Bool = false,
        notes: String = "",
        completionPercentage: Double = 0,
        routine: Routine? = nil
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.activeTime = activeTime
        self.restTime = restTime
        self.calories = calories
        self.isCompleted = isCompleted
        self.notes = notes
        self.completionPercentage = completionPercentage
        self.routine = routine
    }
}
