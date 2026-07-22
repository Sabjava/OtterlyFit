import Foundation
import SwiftData

@MainActor
@Observable
final class RoutineBuilderViewModel {
    let routine: Routine
    var blocks: [RoutineExercise] = []
    var availableExercises: [Exercise] = []
    var errorMessage: String?

    init(routine: Routine) {
        self.routine = routine
        reloadBlocks()
    }

    var estimatedDurationText: String {
        RoutineDurationCalculator.formattedDuration(routine.estimatedDuration)
    }

    func reloadBlocks() {
        blocks = routine.exercises.sorted { $0.order < $1.order }
    }

    func loadExercises(using context: ModelContext) async {
        do {
            let repository = ExerciseRepository(context: context)
            availableExercises = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addExercise(_ exercise: Exercise, using context: ModelContext) async {
        do {
            let repository = RoutineRepository(context: context)
            let configuration = DefaultExerciseData.routineExercise(for: exercise)
            _ = try await repository.addExercise(exercise, to: routine, configuration: configuration)
            refreshEstimatedDuration(using: context)
            reloadBlocks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveBlocks(from source: IndexSet, to destination: Int, using context: ModelContext) async {
        var reordered = blocks
        reordered.move(fromOffsets: source, toOffset: destination)
        blocks = reordered

        do {
            let repository = RoutineRepository(context: context)
            try await repository.reorder(
                routine: routine,
                orderedBlockIDs: reordered.map(\.id)
            )
            refreshEstimatedDuration(using: context)
            reloadBlocks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateBlock(_ block: RoutineExercise, using context: ModelContext) async {
        do {
            let repository = RoutineRepository(context: context)
            _ = try await repository.duplicateBlock(block)
            refreshEstimatedDuration(using: context)
            reloadBlocks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBlocks(at offsets: IndexSet, using context: ModelContext) async {
        for index in offsets.sorted(by: >) {
            guard blocks.indices.contains(index) else { continue }
            await removeBlock(blocks[index], using: context)
        }
    }

    func removeBlock(_ block: RoutineExercise, using context: ModelContext) async {
        do {
            let blockID = block.id
            let repository = RoutineRepository(context: context)
            try await repository.removeBlock(block, from: routine)
            blocks.removeAll { $0.id == blockID }
            refreshEstimatedDuration(using: context)
        } catch {
            errorMessage = error.localizedDescription
            reloadBlocks()
        }
    }

    func saveBlock(_ block: RoutineExercise, using context: ModelContext) async {
        do {
            let repository = RoutineRepository(context: context)
            try await repository.update(routine)
            refreshEstimatedDuration(using: context)
            reloadBlocks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEstimatedDuration(using context: ModelContext) {
        routine.estimatedDuration = RoutineDurationCalculator.estimatedDuration(for: blocks)
        try? context.save()
    }
}
