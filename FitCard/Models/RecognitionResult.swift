import Foundation

struct RecognitionResult: Identifiable, Hashable {
    enum Kind: Hashable {
        case existing(UUID)
        case new
    }

    let id: UUID
    let kind: Kind
    let suggestedName: String
    let suggestedDescription: String
    let recognizedText: String
    let imageData: Data
    let confidence: Double

    init(
        id: UUID = UUID(),
        kind: Kind,
        suggestedName: String,
        suggestedDescription: String,
        recognizedText: String,
        imageData: Data,
        confidence: Double
    ) {
        self.id = id
        self.kind = kind
        self.suggestedName = suggestedName
        self.suggestedDescription = suggestedDescription
        self.recognizedText = recognizedText
        self.imageData = imageData
        self.confidence = confidence
    }
}
