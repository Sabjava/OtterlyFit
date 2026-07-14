import AVFoundation

@MainActor
final class VoicePromptService {
    private let synthesizer = AVSpeechSynthesizer()
    private var isEnabled = true
    private var audioSessionConfigured = false

    func speak(_ text: String, interrupt: Bool = false) {
        speak(text, volume: 0.55, rateMultiplier: 0.82, pitch: 0.92, interrupt: interrupt)
    }

    func speakSoftly(_ text: String, interrupt: Bool = false) {
        speak(text, volume: 0.32, rateMultiplier: 0.75, pitch: 0.88, interrupt: interrupt)
    }

    func stopSpeaking() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .word)
    }

    static func spokenCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopSpeaking()
        }
    }

    private func speak(
        _ text: String,
        volume: Float,
        rateMultiplier: Float,
        pitch: Float,
        interrupt: Bool
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isEnabled, !trimmed.isEmpty else { return }

        configureAudioSessionIfNeeded()

        if interrupt, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rateMultiplier
        utterance.volume = volume
        utterance.pitchMultiplier = pitch
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.preferredLanguages.first ?? "en-US")
        synthesizer.speak(utterance)
    }

    private func configureAudioSessionIfNeeded() {
        guard !audioSessionConfigured else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            audioSessionConfigured = true
        } catch {
            // Voice prompts are optional; continue without audio session changes.
        }
    }
}
