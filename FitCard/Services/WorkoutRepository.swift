import Foundation
import SwiftData

@MainActor
final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ workout: Workout) async throws {
        if workout.modelContext == nil {
            context.insert(workout)
        }
        try context.save()
    }

    func saveCompletedSession(routine: Routine, session: WorkoutSessionSnapshot) async throws -> Workout {
        let sortedBlocks = routine.exercises.sorted { $0.order < $1.order }
        let calories = CalorieEstimator().estimate(activeSeconds: session.activeSeconds)

        let workout = Workout(
            date: Calendar.current.startOfDay(for: session.startTime),
            startTime: session.startTime,
            endTime: session.endTime,
            duration: session.elapsedSeconds,
            activeTime: session.activeSeconds,
            restTime: session.restSeconds,
            calories: calories,
            isCompleted: session.completionPercentage >= 1.0,
            completionPercentage: session.completionPercentage,
            routine: routine
        )

        for stat in session.exerciseStats {
            guard sortedBlocks.indices.contains(stat.blockIndex),
                  let exercise = sortedBlocks[stat.blockIndex].exercise else {
                continue
            }

            let workoutExercise = WorkoutExercise(
                completedSets: stat.completedSets,
                completedRepetitions: stat.completedRepetitions,
                actualDuration: stat.activeSeconds + stat.restSeconds,
                order: stat.blockIndex,
                workout: workout,
                exercise: exercise
            )
            workout.exercises.append(workoutExercise)
        }

        try await save(workout)
        return workout
    }

    func fetchHistory(period: HistoryPeriod) async throws -> [Workout] {
        let startDate = startDate(for: period)
        let descriptor: FetchDescriptor<Workout>

        if let startDate {
            descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate { workout in
                    workout.startTime >= startDate
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Workout>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }

        return try context.fetch(descriptor)
    }

    func fetchDetail(id: UUID) async throws -> Workout {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.id == id
            }
        )

        guard let workout = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }

        return workout
    }

    func delete(_ workout: Workout) async throws {
        context.delete(workout)
        try context.save()
    }

    private func startDate(for period: HistoryPeriod) -> Date? {
        let calendar = Calendar.current
        let now = Date.now

        switch period {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .all:
            return nil
        }
    }
}
