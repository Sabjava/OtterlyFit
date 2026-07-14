import Foundation
import SwiftData

@MainActor
@Observable
final class ExerciseEditViewModel {
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [MuscleGroup]
    var equipment: Equipment
    var difficulty: Difficulty
    var exerciseDescription: String
    var instructions: String
    var tips: String
    var isSaving = false
    var errorMessage: String?

    private let exercise: Exercise?

    var isEditing: Bool { exercise != nil }

    init(exercise: Exercise?) {
        self.exercise = exercise
        name = exercise?.name ?? ""
        category = exercise?.category ?? .strength
        muscleGroups = exercise?.muscleGroups ?? []
        equipment = exercise?.equipment ?? .bodyweight
        difficulty = exercise?.difficulty ?? .beginner
        exerciseDescription = exercise?.exerciseDescription ?? ""
        instructions = exercise?.instructions ?? ""
        tips = exercise?.tips ?? ""
    }

    func save(using context: ModelContext) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Exercise name is required."
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let repository = ExerciseRepository(context: context)

            if let exercise {
                exercise.name = trimmedName
                exercise.category = category
                exercise.muscleGroups = muscleGroups
                exercise.equipment = equipment
                exercise.difficulty = difficulty
                exercise.exerciseDescription = exerciseDescription
                exercise.instructions = instructions
                exercise.tips = tips
                try await repository.update(exercise)
            } else {
                let newExercise = Exercise(
                    name: trimmedName,
                    category: category,
                    muscleGroups: muscleGroups,
                    equipment: equipment,
                    difficulty: difficulty,
                    exerciseDescription: exerciseDescription,
                    instructions: instructions,
                    tips: tips
                )
                try await repository.create(newExercise)
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
