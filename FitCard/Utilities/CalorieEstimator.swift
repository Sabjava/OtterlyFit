import Foundation

struct CalorieEstimator {
    /// Rough estimate: ~5 kcal per minute of active exercise time.
    func estimate(activeSeconds: Int) -> Double {
        max(0, Double(activeSeconds) / 60.0 * 5.0)
    }
}
