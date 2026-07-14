import Foundation
import SwiftData

@MainActor
protocol ExerciseRepositoryProtocol {
    func fetchAll() async throws -> [Exercise]
    func search(query: String) async throws -> [Exercise]
    func filter(muscle: MuscleGroup?, equipment: Equipment?) async throws -> [Exercise]
    func create(_ exercise: Exercise) async throws
    func update(_ exercise: Exercise) async throws
    func delete(_ exercise: Exercise) async throws
    func markUsed(_ exercise: Exercise) async throws
}

@MainActor
protocol RoutineRepositoryProtocol {
    func fetchAll() async throws -> [Routine]
    func create(_ routine: Routine) async throws
    func addExercise(_ exercise: Exercise, to routine: Routine, configuration: RoutineExercise?) async throws -> RoutineExercise
    func reorder(routine: Routine, orderedBlockIDs: [UUID]) async throws
    func duplicateBlock(_ block: RoutineExercise) async throws -> RoutineExercise
    func removeBlock(_ block: RoutineExercise, from routine: Routine) async throws
    func delete(_ routine: Routine) async throws
}

@MainActor
protocol WorkoutRepositoryProtocol {
    func save(_ workout: Workout) async throws
    func saveCompletedSession(routine: Routine, session: WorkoutSessionSnapshot) async throws -> Workout
    func fetchHistory(period: HistoryPeriod) async throws -> [Workout]
    func fetchDetail(id: UUID) async throws -> Workout
    func delete(_ workout: Workout) async throws
}
