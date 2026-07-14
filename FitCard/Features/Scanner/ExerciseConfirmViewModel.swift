import Foundation
import SwiftData

@MainActor
@Observable
final class ExerciseConfirmViewModel {
    var name: String
    var exerciseDescription: String
    var instructions: String
    var category: ExerciseCategory
    var difficulty: Difficulty
    var isSaving = false
    var errorMessage: String?
    var didSave = false

    let recognitionResult: RecognitionResult
    let isExistingMatch: Bool
    let confidence: Double

    private let matchedExerciseID: UUID?

    init(recognitionResult: RecognitionResult, existingExercise: Exercise?) {
        self.recognitionResult = recognitionResult
        self.isExistingMatch = existingExercise != nil
        self.confidence = recognitionResult.confidence
        self.matchedExerciseID = existingExercise?.id

        if let existingExercise {
            name = existingExercise.name
            exerciseDescription = recognitionResult.suggestedDescription.isEmpty
                ? existingExercise.exerciseDescription
                : recognitionResult.suggestedDescription
            instructions = existingExercise.instructions
            category = existingExercise.category
            difficulty = existingExercise.difficulty
        } else {
            name = recognitionResult.suggestedName
            exerciseDescription = recognitionResult.suggestedDescription
            instructions = ""
            category = .strength
            difficulty = .beginner
        }
    }

    func save(using repository: ExerciseRepository, context: ModelContext) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Exercise name is required."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            if let matchedExerciseID,
               let existingExercise = try fetchExercise(id: matchedExerciseID, context: context) {
                existingExercise.name = trimmedName
                existingExercise.exerciseDescription = exerciseDescription
                existingExercise.instructions = instructions
                existingExercise.category = category
                existingExercise.difficulty = difficulty
                existingExercise.cardImageData = recognitionResult.imageData
                try await repository.update(existingExercise)
                try await repository.markUsed(existingExercise)
            } else {
                let exercise = Exercise(
                    name: trimmedName,
                    category: category,
                    difficulty: difficulty,
                    cardImageData: recognitionResult.imageData,
                    exerciseDescription: exerciseDescription,
                    instructions: instructions
                )
                try await repository.create(exercise)
            }

            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchExercise(id: UUID, context: ModelContext) throws -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.id == id
            }
        )
        return try context.fetch(descriptor).first
    }
}
