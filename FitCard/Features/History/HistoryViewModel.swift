import Foundation
import SwiftData

@MainActor
@Observable
final class HistoryViewModel {
    var workouts: [Workout] = []
    var selectedPeriod: HistoryPeriod = .all
    var isLoading = false
    var errorMessage: String?

    var groupedSections: [WorkoutHistorySection] {
        let grouped = Dictionary(grouping: workouts) { workout in
            Calendar.current.startOfDay(for: workout.startTime)
        }

        return grouped
            .map { date, workouts in
                WorkoutHistorySection(
                    date: date,
                    title: sectionTitle(for: date),
                    workouts: workouts.sorted { $0.startTime > $1.startTime }
                )
            }
            .sorted { $0.date > $1.date }
    }

    func load(using context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let repository = WorkoutRepository(context: context)
            workouts = try await repository.fetchHistory(period: selectedPeriod)
        } catch {
            errorMessage = error.localizedDescription
            workouts = []
        }
    }

    func delete(_ workout: Workout, using context: ModelContext) async {
        let repository = WorkoutRepository(context: context)
        try? await repository.delete(workout)
        await load(using: context)
    }

    func workoutTitle(_ workout: Workout) -> String {
        workout.routine?.name ?? "Workout"
    }

    func durationText(for workout: Workout) -> String {
        formatDuration(workout.duration)
    }

    func completionText(for workout: Workout) -> String {
        "\(Int(workout.completionPercentage * 100))%"
    }

    func timeText(for workout: Workout) -> String {
        workout.startTime.formatted(date: .omitted, time: .shortened)
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
