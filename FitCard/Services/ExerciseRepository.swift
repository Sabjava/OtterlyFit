import Foundation
import SwiftData

@MainActor
final class ExerciseRepository: ExerciseRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func search(query: String) async throws -> [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return try await fetchAll()
        }

        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.name.localizedStandardContains(trimmed)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func filter(muscle: MuscleGroup?, equipment: Equipment?) async throws -> [Exercise] {
        var results = try await fetchAll()

        if let muscle {
            let rawValue = muscle.rawValue
            results = results.filter { $0.muscleGroupRawValues.contains(rawValue) }
        }

        if let equipment {
            results = results.filter { $0.equipment == equipment }
        }

        return results
    }

    func create(_ exercise: Exercise) async throws {
        context.insert(exercise)
        try context.save()
    }

    func update(_ exercise: Exercise) async throws {
        try context.save()
    }

    func delete(_ exercise: Exercise) async throws {
        context.delete(exercise)
        try context.save()
    }

    func markUsed(_ exercise: Exercise) async throws {
        exercise.lastUsedAt = .now
        try context.save()
    }
}
