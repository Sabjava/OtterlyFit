import SwiftData

enum FitCardSchema {
    static let models: [any PersistentModel.Type] = [
        Exercise.self,
        Routine.self,
        RoutineExercise.self,
        Workout.self,
        WorkoutExercise.self,
    ]

    static var schema: Schema {
        Schema(models)
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            let configuration = ModelConfiguration(schema: FitCardSchema.schema)
            return try ModelContainer(for: FitCardSchema.schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    @MainActor
    static func normalizeRoutineDefaultsIfNeeded() {
        let context = shared.mainContext
        guard let blocks = try? context.fetch(FetchDescriptor<RoutineExercise>()) else { return }

        var changed = false
        for block in blocks where block.restBetweenSets == 60 {
            block.restBetweenSets = AppConstants.defaultRestBetweenSets
            changed = true
        }

        if changed {
            try? context.save()
        }
    }

    @MainActor
    static func seedSampleDataIfNeeded() {
        #if DEBUG
        let context = shared.mainContext
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let existingExerciseCount = (try? context.fetchCount(exerciseDescriptor)) ?? 0

        if existingExerciseCount == 0 {
            PreviewData.insertSampleData(into: context)
            try? context.save()
            return
        }

        let workoutDescriptor = FetchDescriptor<Workout>()
        let existingWorkoutCount = (try? context.fetchCount(workoutDescriptor)) ?? 0
        guard existingWorkoutCount == 0 else { return }

        PreviewData.insertSampleWorkout(into: context)
        try? context.save()
        #endif
    }

    @MainActor
    static let preview: ModelContainer = {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: FitCardSchema.schema, configurations: [configuration])
            PreviewData.insertSampleData(into: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error.localizedDescription)")
        }
    }()
}
