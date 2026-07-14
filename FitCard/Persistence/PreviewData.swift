import Foundation
import SwiftData

enum PreviewData {
    @MainActor
    static func insertSampleData(into context: ModelContext) {
        let pushUp = Exercise(
            name: "Push-Up",
            category: .strength,
            muscleGroups: [.chest, .arms, .core],
            equipment: .bodyweight,
            difficulty: .beginner,
            exerciseDescription: "Classic bodyweight chest exercise.",
            instructions: "Keep your body in a straight line. Lower until chest nearly touches the floor.",
            tips: "Engage your core throughout the movement.",
            isFavorite: true
        )

        let squat = Exercise(
            name: "Bodyweight Squat",
            category: .strength,
            muscleGroups: [.legs, .core],
            equipment: .bodyweight,
            difficulty: .beginner,
            exerciseDescription: "Fundamental lower-body movement.",
            instructions: "Feet shoulder-width apart. Lower hips back and down, then stand.",
            tips: "Keep knees tracking over toes."
        )

        let plank = Exercise(
            name: "Plank",
            category: .strength,
            muscleGroups: [.core],
            equipment: .bodyweight,
            difficulty: .intermediate,
            exerciseDescription: "Isometric core hold.",
            instructions: "Hold a straight line from head to heels on forearms or hands.",
            tips: "Do not let hips sag."
        )

        context.insert(pushUp)
        context.insert(squat)
        context.insert(plank)

        let morningRoutine = Routine(
            name: "Morning Strength",
            routineDescription: "Quick full-body routine to start the day.",
            category: .strength,
            estimatedDuration: 900,
            isFavorite: true
        )

        let blocks = [
            RoutineExercise(order: 0, sets: 3, repetitions: 12, restBetweenSets: 30, routine: morningRoutine, exercise: pushUp),
            RoutineExercise(order: 1, sets: 3, repetitions: 15, restBetweenSets: 30, routine: morningRoutine, exercise: squat),
            RoutineExercise(order: 2, sets: 3, repetitions: 1, secondsPerRep: 30, restBetweenSets: 30, routine: morningRoutine, exercise: plank),
        ]

        context.insert(morningRoutine)
        blocks.forEach { context.insert($0) }

        let completedWorkout = Workout(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            startTime: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            endTime: Calendar.current.date(byAdding: .hour, value: -1, to: .now),
            duration: 840,
            activeTime: 600,
            restTime: 240,
            calories: 85,
            isCompleted: true,
            completionPercentage: 1.0,
            routine: morningRoutine
        )

        let workoutExercises = [
            WorkoutExercise(completedSets: 3, completedRepetitions: 36, actualDuration: 180, order: 0, workout: completedWorkout, exercise: pushUp),
            WorkoutExercise(completedSets: 3, completedRepetitions: 45, actualDuration: 210, order: 1, workout: completedWorkout, exercise: squat),
            WorkoutExercise(completedSets: 3, completedRepetitions: 3, actualDuration: 90, order: 2, workout: completedWorkout, exercise: plank),
        ]

        context.insert(completedWorkout)
        workoutExercises.forEach { context.insert($0) }
    }

    @MainActor
    static func insertSampleWorkout(into context: ModelContext) {
        let routineDescriptor = FetchDescriptor<Routine>(
            predicate: #Predicate { $0.name == "Morning Strength" }
        )
        let exerciseDescriptor = FetchDescriptor<Exercise>()

        guard
            let routine = try? context.fetch(routineDescriptor).first,
            let exercises = try? context.fetch(exerciseDescriptor),
            !exercises.isEmpty
        else {
            return
        }

        let pushUp = exercises.first { $0.name == "Push-Up" } ?? exercises[0]
        let squat = exercises.first { $0.name == "Bodyweight Squat" } ?? exercises[0]
        let plank = exercises.first { $0.name == "Plank" } ?? exercises[0]

        let completedWorkout = Workout(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            startTime: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            endTime: Calendar.current.date(byAdding: .hour, value: -1, to: .now),
            duration: 840,
            activeTime: 600,
            restTime: 240,
            calories: 85,
            isCompleted: true,
            completionPercentage: 1.0,
            routine: routine
        )

        let workoutExercises = [
            WorkoutExercise(completedSets: 3, completedRepetitions: 36, actualDuration: 180, order: 0, workout: completedWorkout, exercise: pushUp),
            WorkoutExercise(completedSets: 3, completedRepetitions: 45, actualDuration: 210, order: 1, workout: completedWorkout, exercise: squat),
            WorkoutExercise(completedSets: 3, completedRepetitions: 3, actualDuration: 90, order: 2, workout: completedWorkout, exercise: plank),
        ]

        context.insert(completedWorkout)
        workoutExercises.forEach { context.insert($0) }
    }
}
