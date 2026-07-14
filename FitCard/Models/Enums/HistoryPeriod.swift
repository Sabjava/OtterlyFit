import Foundation

enum HistoryPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            "Today"
        case .week:
            "Week"
        case .month:
            "Month"
        case .all:
            "All"
        }
    }
}

struct WorkoutHistorySection: Identifiable {
    let date: Date
    let title: String
    let workouts: [Workout]

    var id: Date { date }
}
