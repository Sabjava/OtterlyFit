import Foundation
import SwiftData

@MainActor
@Observable
final class WorkoutSummaryViewModel {
    let routine: Routine
    let session: WorkoutSessionSnapshot

    private(set) var savedWorkout: Workout?
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var errorMessage: String?

    init(routine: Routine, session: WorkoutSessionSnapshot) {
        self.routine = routine
        self.session = session
    }

    var durationText: String {
        formatDuration(session.elapsedSeconds)
    }

    var activeTimeText: String {
        formatDuration(session.activeSeconds)
    }

    var restTimeText: String {
        formatDuration(session.restSeconds)
    }

    var completionText: String {
        "\(Int(session.completionPercentage * 100))%"
    }

    var startTimeText: String {
        session.startTime.formatted(date: .abbreviated, time: .shortened)
    }

    var endTimeText: String {
        session.endTime.formatted(date: .abbreviated, time: .shortened)
    }

    var caloriesText: String {
        let calories = CalorieEstimator().estimate(activeSeconds: session.activeSeconds)
        return String(format: "%.0f kcal", calories)
    }

    func save(using context: ModelContext) async {
        guard !didSave, !isSaving else { return }

        isSaving = true
        errorMessage = nil

        do {
            let repository = WorkoutRepository(context: context)
            savedWorkout = try await repository.saveCompletedSession(routine: routine, session: session)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
