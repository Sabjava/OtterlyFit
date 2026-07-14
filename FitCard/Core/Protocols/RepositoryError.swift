import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            "The requested item could not be found."
        case .saveFailed:
            "Failed to save changes."
        }
    }
}
