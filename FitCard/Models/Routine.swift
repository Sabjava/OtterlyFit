import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var routineDescription: String
    var category: ExerciseCategory
    var estimatedDuration: Int
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise] = []

    @Relationship(inverse: \Workout.routine)
    var workouts: [Workout] = []

    init(
        id: UUID = UUID(),
        name: String,
        routineDescription: String = "",
        category: ExerciseCategory = .strength,
        estimatedDuration: Int = 0,
        isFavorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.routineDescription = routineDescription
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
