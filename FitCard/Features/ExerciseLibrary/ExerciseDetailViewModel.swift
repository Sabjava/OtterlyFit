import Foundation
import SwiftData

@MainActor
@Observable
final class ExerciseDetailViewModel {
    let exercise: Exercise

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    func toggleFavorite(using context: ModelContext) async {
        let repository = ExerciseRepository(context: context)
        exercise.isFavorite.toggle()
        try? await repository.update(exercise)
    }

    func delete(using context: ModelContext) async throws {
        let repository = ExerciseRepository(context: context)
        try await repository.delete(exercise)
    }
}
