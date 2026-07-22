import AVFoundation

@MainActor
final class VoicePromptService {
    private let synthesizer = AVSpeechSynthesizer()
    private var isEnabled = true
    private var audioSessionConfigured = false
    private var cachedVoice: AVSpeechSynthesisVoice?

    private static let preferredLanguage = "en-US"

    /// Warm, natural delivery for general cues — quick and bright.
    func speak(_ text: String, interrupt: Bool = false) {
        speak(
            text,
            volume: 0.80,
            rateMultiplier: 0.98,
            pitch: 1.06,
            preUtteranceDelay: 0.04,
            postUtteranceDelay: 0.05,
            interrupt: interrupt
        )
    }

    /// Enthusiastic coach energy — clear, cheerful, brisk.
    func speakEnergetically(_ text: String, interrupt: Bool = false) {
        speak(
            text,
            volume: 0.84,
            rateMultiplier: 1.03,
            pitch: 1.10,
            preUtteranceDelay: 0.04,
            postUtteranceDelay: 0.05,
            interrupt: interrupt
        )
    }

    /// Soft recovery tone for rest cues — still a bit quicker than before.
    func speakSoftly(_ text: String, interrupt: Bool = false) {
        speak(
            text,
            volume: 0.70,
            rateMultiplier: 0.95,
            pitch: 1.05,
            preUtteranceDelay: 0.05,
            postUtteranceDelay: 0.08,
            interrupt: interrupt
        )
    }

    func speakCountdown(_ value: Int, includeReady: Bool = false, interrupt: Bool = false) {
        let count = Self.spokenCount(value)
        // Exclamation + ellipsis give TTS a natural breath and lift.
        let text = includeReady ? "Alright… \(count)!" : "\(count)!"
        speak(
            text,
            volume: 0.85,
            rateMultiplier: 0.97,
            pitch: 1.10,
            preUtteranceDelay: 0.03,
            postUtteranceDelay: 0.04,
            interrupt: interrupt
        )
    }

    func speakRepCount(
        _ value: Int,
        isFirstOfSet: Bool = false,
        isLastOfSet: Bool = false,
        interrupt: Bool = false
    ) {
        let count = Self.spokenCount(value)
        // Keep every number; cheerful pitch with a mid-set smile and last-rep lift.
        let pitch: Float
        if isLastOfSet {
            pitch = 1.10
        } else if isFirstOfSet {
            pitch = 1.07
        } else {
            pitch = 1.08
        }

        speak(
            count,
            volume: isLastOfSet ? 0.86 : 0.82,
            rateMultiplier: 0.95,
            pitch: pitch,
            preUtteranceDelay: isFirstOfSet ? 0.05 : 0.03,
            postUtteranceDelay: 0.04,
            interrupt: interrupt
        )
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
        preUtteranceDelay: TimeInterval = 0,
        postUtteranceDelay: TimeInterval = 0,
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
        utterance.preUtteranceDelay = preUtteranceDelay
        utterance.postUtteranceDelay = postUtteranceDelay
        utterance.voice = preferredVoice()
        synthesizer.speak(utterance)
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice {
        if let cachedVoice {
            return cachedVoice
        }

        let usVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language == Self.preferredLanguage || voice.language.hasPrefix("en-US")
        }

        let voice = selectCheerfulUSVoice(from: usVoices)
            ?? AVSpeechSynthesisVoice(language: Self.preferredLanguage)
            ?? AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("en") }
            ?? AVSpeechSynthesisVoice(language: "en-US")!

        cachedVoice = voice
        return voice
    }

    /// Prefer premium → enhanced → default among en-US voices; boost cheerful US names.
    private func selectCheerfulUSVoice(from voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        guard !voices.isEmpty else { return nil }

        let ranked = voices.sorted { lhs, rhs in
            let leftScore = voiceCheerScore(lhs)
            let rightScore = voiceCheerScore(rhs)
            if leftScore != rightScore {
                return leftScore > rightScore
            }
            return lhs.name < rhs.name
        }

        return ranked.first
    }

    private func voiceCheerScore(_ voice: AVSpeechSynthesisVoice) -> Int {
        var score = 0

        // Strict en-US preference.
        if voice.language == Self.preferredLanguage {
            score += 50
        } else if voice.language.hasPrefix("en-US") {
            score += 40
        }

        // Quality: premium (iOS 17+) beats enhanced; both beat default.
        if #available(iOS 17.0, *) {
            if voice.quality == .premium {
                score += 100
            } else if voice.quality == .enhanced {
                score += 70
            }
        } else if voice.quality == .enhanced {
            score += 70
        }

        let name = voice.name.lowercased()
        // Cheerful US English voices first.
        let cheerfulUSNames = [
            "samantha", "ava", "zoe", "nora", "allison", "susan"
        ]
        if cheerfulUSNames.contains(where: { name.contains($0) }) {
            score += 45
        }

        // Secondary warm US names.
        let warmUSNames = ["kathy", "serena", "nicky"]
        if warmUSNames.contains(where: { name.contains($0) }) {
            score += 25
        }

        if name.contains("premium") || name.contains("neural") || name.contains("natural") {
            score += 10
        }

        return score
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
