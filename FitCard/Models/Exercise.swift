import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var muscleGroupRawValues: [String]
    var equipment: Equipment
    var difficulty: Difficulty
    var cardImageData: Data?
    var exerciseDescription: String
    var instructions: String
    var tips: String
    var isFavorite: Bool
    var createdAt: Date
    var lastUsedAt: Date?

    @Relationship(inverse: \RoutineExercise.exercise)
    var routineExercises: [RoutineExercise] = []

    @Relationship(inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise] = []

    var muscleGroups: [MuscleGroup] {
        get { muscleGroupRawValues.compactMap(MuscleGroup.init(rawValue:)) }
        set { muscleGroupRawValues = newValue.map(\.rawValue) }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory = .strength,
        muscleGroups: [MuscleGroup] = [],
        equipment: Equipment = .bodyweight,
        difficulty: Difficulty = .beginner,
        cardImageData: Data? = nil,
        exerciseDescription: String = "",
        instructions: String = "",
        tips: String = "",
        isFavorite: Bool = false,
        createdAt: Date = .now,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroupRawValues = muscleGroups.map(\.rawValue)
        self.equipment = equipment
        self.difficulty = difficulty
        self.cardImageData = cardImageData
        self.exerciseDescription = exerciseDescription
        self.instructions = instructions
        self.tips = tips
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
