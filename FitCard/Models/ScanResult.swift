import Foundation

struct ScanResult: Sendable, Equatable {
    let imageData: Data
    let recognizedText: String
}
