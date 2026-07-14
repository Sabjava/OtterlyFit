import Foundation

final class TimerEngine {
    func countdown(from seconds: Int) -> AsyncStream<Int> {
        AsyncStream { continuation in
            let task = Task {
                var remaining = seconds
                while remaining >= 0 {
                    if Task.isCancelled {
                        continuation.finish()
                        return
                    }
                    continuation.yield(remaining)
                    if remaining == 0 { break }
                    remaining -= 1
                    try? await Task.sleep(for: .seconds(1))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func interval() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    if Task.isCancelled { break }
                    continuation.yield(())
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
