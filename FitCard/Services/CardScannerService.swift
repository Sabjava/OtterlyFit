import Foundation
import UIKit
import Vision

enum ScannerError: LocalizedError {
    case invalidImage
    case textRecognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "The captured image could not be processed."
        case .textRecognitionFailed:
            "Text recognition failed. Try scanning again with better lighting."
        }
    }
}

final class CardScannerService {
    func scanCard(from image: UIImage) async throws -> ScanResult {
        let imageData = image.jpegData(compressionQuality: 0.85) ?? Data()
        let recognizedText = try await extractText(from: image)
        return ScanResult(imageData: imageData, recognizedText: recognizedText)
    }

    private func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedLines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedLines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: cgImageOrientation(from: image.imageOrientation),
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ScannerError.textRecognitionFailed)
            }
        }
    }

    private func cgImageOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
