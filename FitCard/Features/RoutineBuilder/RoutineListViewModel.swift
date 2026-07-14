import Foundation
import SwiftData

@MainActor
@Observable
final class RoutineListViewModel {
    var routines: [Routine] = []
    var isLoading = false
    var errorMessage: String?

    func load(using context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let repository = RoutineRepository(context: context)
            routines = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
            routines = []
        }
    }

    func createRoutine(name: String, using context: ModelContext) async -> Routine? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let routine = Routine(name: trimmed)
        do {
            let repository = RoutineRepository(context: context)
            try await repository.create(routine)
            await load(using: context)
            return routine
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func toggleFavorite(_ routine: Routine, using context: ModelContext) async {
        let repository = RoutineRepository(context: context)
        routine.isFavorite.toggle()
        try? await repository.update(routine)
        await load(using: context)
    }

    func delete(_ routine: Routine, using context: ModelContext) async {
        let repository = RoutineRepository(context: context)
        try? await repository.delete(routine)
        await load(using: context)
    }
}
