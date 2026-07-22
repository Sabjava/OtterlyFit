import Foundation
import SwiftData

enum DefaultExerciseData {
    struct BlockDefaults {
        let sets: Int
        let repetitions: Int
        let weight: Double?
    }

    private struct Definition {
        let name: String
        let imageFilename: String
        let category: ExerciseCategory
        let muscleGroups: [MuscleGroup]
        let equipment: Equipment
        let difficulty: Difficulty
        let blockDefaults: BlockDefaults?
    }

    private static let exercises: [Definition] = [
        Definition(
            name: "Rope Jumps",
            imageFilename: "rope-jumps",
            category: .cardio,
            muscleGroups: [.fullBody, .legs],
            equipment: .other,
            difficulty: .beginner,
            blockDefaults: BlockDefaults(sets: 2, repetitions: 30, weight: nil)
        ),
        Definition(
            name: "Farmer Walk",
            imageFilename: "farmer-walk",
            category: .strength,
            muscleGroups: [.fullBody, .legs, .core],
            equipment: .dumbbell,
            difficulty: .intermediate,
            blockDefaults: BlockDefaults(sets: 4, repetitions: 50, weight: 32)
        ),
        Definition(
            name: "Kettlebell Deadlift",
            imageFilename: "kettlebell-deadlift",
            category: .strength,
            muscleGroups: [.legs, .back, .core],
            equipment: .kettlebell,
            difficulty: .beginner,
            blockDefaults: BlockDefaults(sets: 3, repetitions: 15, weight: 32)
        ),
        Definition(
            name: "Goblet Squat with Kettlebell",
            imageFilename: "goblet-squat-with-kettlebell",
            category: .strength,
            muscleGroups: [.legs, .core],
            equipment: .kettlebell,
            difficulty: .intermediate,
            blockDefaults: BlockDefaults(sets: 3, repetitions: 10, weight: nil)
        ),
        Definition(
            name: "High Plank Leg Lift with Band",
            imageFilename: "high-plank-leg-lift-with-band",
            category: .strength,
            muscleGroups: [.core, .legs],
            equipment: .band,
            difficulty: .intermediate,
            blockDefaults: BlockDefaults(sets: 3, repetitions: 10, weight: nil)
        ),
        Definition(
            name: "Squat Side Step with Ankle Band",
            imageFilename: "squat-side-step-with-ankle-band",
            category: .strength,
            muscleGroups: [.legs, .core],
            equipment: .band,
            difficulty: .beginner,
            blockDefaults: BlockDefaults(sets: 3, repetitions: 10, weight: nil)
        ),
        Definition(
            name: "Walk Upstairs",
            imageFilename: "walk-upstairs",
            category: .cardio,
            muscleGroups: [.legs, .core],
            equipment: .bodyweight,
            difficulty: .beginner,
            blockDefaults: BlockDefaults(sets: 5, repetitions: 10, weight: nil)
        ),
        Definition(
            name: "Plank with Sliders",
            imageFilename: "plank-with-sliders",
            category: .strength,
            muscleGroups: [.core, .legs],
            equipment: .other,
            difficulty: .intermediate,
            blockDefaults: BlockDefaults(sets: 3, repetitions: 10, weight: nil)
        ),
    ]

    static func blockDefaults(for exercise: Exercise) -> BlockDefaults? {
        exercises.first { $0.name == exercise.name }?.blockDefaults
    }

    static func routineExercise(for exercise: Exercise) -> RoutineExercise? {
        guard let defaults = blockDefaults(for: exercise) else { return nil }

        return RoutineExercise(
            sets: defaults.sets,
            repetitions: defaults.repetitions,
            weight: defaults.weight
        )
    }

    @MainActor
    static func seedIfNeeded(into context: ModelContext) {
        guard let existingExercises = try? context.fetch(FetchDescriptor<Exercise>()) else { return }

        let existingByName = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.name, $0) })
        var changed = false

        for definition in exercises {
            if let existing = existingByName[definition.name] {
                if let imageData = DefaultCardLoader.imageData(named: definition.imageFilename),
                   existing.cardImageData != imageData {
                    existing.cardImageData = imageData
                    changed = true
                }
                continue
            }

            let exercise = Exercise(
                name: definition.name,
                category: definition.category,
                muscleGroups: definition.muscleGroups,
                equipment: definition.equipment,
                difficulty: definition.difficulty,
                cardImageData: DefaultCardLoader.imageData(named: definition.imageFilename)
            )

            context.insert(exercise)
            changed = true
        }

        if changed {
            try? context.save()
        }
    }
}
