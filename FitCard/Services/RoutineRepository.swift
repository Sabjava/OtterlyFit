import Foundation
import SwiftData

@MainActor
final class RoutineRepository: RoutineRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func create(_ routine: Routine) async throws {
        context.insert(routine)
        try context.save()
    }

    func update(_ routine: Routine) async throws {
        routine.updatedAt = .now
        try context.save()
    }

    func addExercise(
        _ exercise: Exercise,
        to routine: Routine,
        configuration: RoutineExercise? = nil
    ) async throws -> RoutineExercise {
        let nextOrder = (routine.exercises.map(\.order).max() ?? -1) + 1
        let block = configuration ?? RoutineExercise()
        block.order = nextOrder
        block.routine = routine
        block.exercise = exercise

        context.insert(block)
        routine.updatedAt = .now
        try context.save()
        return block
    }

    func reorder(routine: Routine, orderedBlockIDs: [UUID]) async throws {
        for (index, id) in orderedBlockIDs.enumerated() {
            guard let block = routine.exercises.first(where: { $0.id == id }) else { continue }
            block.order = index
        }
        routine.updatedAt = .now
        try context.save()
    }

    func duplicateBlock(_ block: RoutineExercise) async throws -> RoutineExercise {
        guard let routine = block.routine else {
            throw RepositoryError.notFound
        }

        let nextOrder = (routine.exercises.map(\.order).max() ?? -1) + 1
        let copy = RoutineExercise(
            order: nextOrder,
            sets: block.sets,
            repetitions: block.repetitions,
            secondsPerRep: block.secondsPerRep,
            restBetweenReps: block.restBetweenReps,
            restBetweenSets: block.restBetweenSets,
            weight: block.weight,
            notes: block.notes,
            routine: routine,
            exercise: block.exercise
        )

        context.insert(copy)
        routine.updatedAt = .now
        try context.save()
        return copy
    }

    func removeBlock(_ block: RoutineExercise, from routine: Routine) async throws {
        context.delete(block)
        reindexBlocks(in: routine)
        routine.updatedAt = .now
        try context.save()
    }

    func delete(_ routine: Routine) async throws {
        context.delete(routine)
        try context.save()
    }

    private func reindexBlocks(in routine: Routine) {
        let sortedBlocks = routine.exercises.sorted { $0.order < $1.order }
        for (index, block) in sortedBlocks.enumerated() {
            block.order = index
        }
    }
}
