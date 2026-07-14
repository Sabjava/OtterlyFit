import Foundation
import SwiftData

@MainActor
@Observable
final class ExerciseListViewModel {
    var exercises: [Exercise] = []
    var searchQuery = ""
    var selectedMuscle: MuscleGroup?
    var selectedEquipment: Equipment?
    var favoritesOnly = false
    var isLoading = false
    var errorMessage: String?

    func load(using context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let repository = ExerciseRepository(context: context)
            var results = try await repository.search(query: searchQuery)

            if favoritesOnly {
                results = results.filter(\.isFavorite)
            }

            if let selectedMuscle {
                results = results.filter { $0.muscleGroups.contains(selectedMuscle) }
            }

            if let selectedEquipment {
                results = results.filter { $0.equipment == selectedEquipment }
            }

            exercises = results
        } catch {
            errorMessage = error.localizedDescription
            exercises = []
        }
    }

    func toggleFavorite(for exercise: Exercise, using context: ModelContext) async {
        let repository = ExerciseRepository(context: context)
        exercise.isFavorite.toggle()
        try? await repository.update(exercise)
        await load(using: context)
    }

    func delete(_ exercise: Exercise, using context: ModelContext) async {
        let repository = ExerciseRepository(context: context)
        try? await repository.delete(exercise)
        await load(using: context)
    }

    func clearFilters() {
        selectedMuscle = nil
        selectedEquipment = nil
        favoritesOnly = false
    }

    var hasActiveFilters: Bool {
        favoritesOnly || selectedMuscle != nil || selectedEquipment != nil
    }
}
