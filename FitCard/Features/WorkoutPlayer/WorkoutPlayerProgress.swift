import Foundation

struct WorkoutPlayerProgress: Equatable {
    let overallFraction: Double
    let phaseFraction: Double
    let elapsedSeconds: Int
    let completedSets: Int
    let completedRepetitions: Int
    let currentExerciseIndex: Int
    let totalExercises: Int
}

struct ExerciseSessionStats: Equatable {
    var completedSets: Int = 0
    var completedRepetitions: Int = 0
    var activeSeconds: Int = 0
    var restSeconds: Int = 0
}

struct WorkoutExerciseSessionStats: Equatable, Identifiable {
    var id: Int { blockIndex }

    let blockIndex: Int
    let exerciseName: String
    let completedSets: Int
    let completedRepetitions: Int
    let activeSeconds: Int
    let restSeconds: Int
}

struct WorkoutSessionSnapshot: Equatable, Identifiable {
    let routineName: String
    let startTime: Date
    let endTime: Date
    let elapsedSeconds: Int
    let activeSeconds: Int
    let restSeconds: Int
    let completedSets: Int
    let completedRepetitions: Int
    let completionPercentage: Double
    let exerciseStats: [WorkoutExerciseSessionStats]

    var id: String {
        "\(startTime.timeIntervalSince1970)-\(endTime.timeIntervalSince1970)"
    }
}
