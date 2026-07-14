import Foundation
import SwiftData
import UIKit
import VisionKit

@MainActor
@Observable
final class CardScannerViewModel {
    var scanResult: ScanResult?
    var capturedImage: UIImage?
    var isPresentingScanner = false
    var isProcessing = false
    var errorMessage: String?
    var pendingRecognition: RecognitionResult?
    var matchedExercise: Exercise?

    private let scannerService: CardScannerService

    var isDocumentScannerAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    init(scannerService: CardScannerService = CardScannerService()) {
        self.scannerService = scannerService
    }

    func startScan() {
        guard isDocumentScannerAvailable else {
            errorMessage = "Document scanning requires a device with a camera."
            return
        }
        errorMessage = nil
        isPresentingScanner = true
    }

    func handleCapturedImages(_ images: [UIImage]) async {
        isPresentingScanner = false
        guard let image = images.first else { return }

        isProcessing = true
        defer { isProcessing = false }

        pendingRecognition = nil
        matchedExercise = nil

        do {
            let result = try await scannerService.scanCard(from: image)
            scanResult = result
            capturedImage = image
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            scanResult = nil
            capturedImage = nil
        }
    }

    func prepareConfirmation(using context: ModelContext) async {
        guard let scanResult else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let repository = ExerciseRepository(context: context)
            let recognitionService = ExerciseRecognitionService(exerciseRepository: repository)
            let result = try await recognitionService.recognize(
                text: scanResult.recognizedText,
                imageData: scanResult.imageData
            )

            pendingRecognition = result

            if case .existing(let exerciseID) = result.kind {
                matchedExercise = try fetchExercise(id: exerciseID, context: context)
            } else {
                matchedExercise = nil
            }

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            pendingRecognition = nil
            matchedExercise = nil
        }
    }

    func handleCancel() {
        isPresentingScanner = false
    }

    func loadSampleScan(_ kind: SampleScanKind) async {
        await handleCapturedImages([SampleScanProvider.image(for: kind)])
    }

    func reset() {
        scanResult = nil
        capturedImage = nil
        errorMessage = nil
        pendingRecognition = nil
        matchedExercise = nil
    }

    private func fetchExercise(id: UUID, context: ModelContext) throws -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.id == id
            }
        )
        return try context.fetch(descriptor).first
    }
}
