import Foundation

@MainActor
final class ExerciseRecognitionService {
    private let exerciseRepository: ExerciseRepository
    private let matchThreshold = 0.65

    init(exerciseRepository: ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }

    func recognize(text: String, imageData: Data) async throws -> RecognitionResult {
        let exercises = try await exerciseRepository.fetchAll()
        let metadata = Self.parseMetadata(from: text)
        let normalizedText = text.lowercased()

        var bestMatch: (Exercise, Double)?

        for exercise in exercises {
            let score = matchScore(
                suggestedName: metadata.name,
                exerciseName: exercise.name,
                fullText: normalizedText
            )
            if score > (bestMatch?.1 ?? 0) {
                bestMatch = (exercise, score)
            }
        }

        if let bestMatch, bestMatch.1 >= matchThreshold {
            return RecognitionResult(
                kind: .existing(bestMatch.0.id),
                suggestedName: bestMatch.0.name,
                suggestedDescription: metadata.description.isEmpty ? bestMatch.0.exerciseDescription : metadata.description,
                recognizedText: text,
                imageData: imageData,
                confidence: bestMatch.1
            )
        }

        return RecognitionResult(
            kind: .new,
            suggestedName: metadata.name,
            suggestedDescription: metadata.description,
            recognizedText: text,
            imageData: imageData,
            confidence: 0
        )
    }

    static func parseMetadata(from text: String) -> (name: String, description: String) {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let name = lines.first ?? "Untitled Exercise"
        let description = lines.dropFirst().joined(separator: "\n")
        return (name, description)
    }

    private func matchScore(suggestedName: String, exerciseName: String, fullText: String) -> Double {
        let suggested = suggestedName.lowercased()
        let name = exerciseName.lowercased()

        if suggested == name { return 1.0 }
        if fullText.contains(name) { return 0.9 }
        if suggested.contains(name) || name.contains(suggested) { return 0.75 }

        let suggestedWords = Set(suggested.split(separator: " ").map(String.init))
        let nameWords = Set(name.split(separator: " ").map(String.init))
        guard !nameWords.isEmpty else { return 0 }

        let overlap = Double(suggestedWords.intersection(nameWords).count) / Double(nameWords.count)
        return overlap * 0.8
    }
}
