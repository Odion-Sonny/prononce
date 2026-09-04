import Foundation
import AVFoundation

/// Voice metadata wrapper for UI presentation and selection
struct FrenchVoiceInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    let regionName: String
    let isEnhanced: Bool
    
    var displayName: String {
        if isEnhanced {
            return "\(name) (Enhanced)"
        }
        return name
    }
}

/// Service responsible for local, native macOS French speech synthesis.
/// Uses AVFoundation without any external APIs, network calls, or cloud latency.
final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private let settings = AppSettings.shared

    @Published private(set) var isSpeaking: Bool = false
    @Published private(set) var availableFrenchVoices: [FrenchVoiceInfo] = []
    @Published private(set) var currentVoiceInfo: FrenchVoiceInfo?

    /// Maximum characters allowed per speech request to prevent system freezes
    static let maxTextLength = 2500

    /// Callback triggered when speech completes
    var onSpeechCompleted: (() -> Void)?
    
    /// Callback triggered when speech error occurs (e.g. no voice found)
    var onSpeechError: ((String) -> Void)?

    override private init() {
        super.init()
        synthesizer.delegate = self
        reloadVoices()
    }

    /// Scans installed macOS voices for French voices
    func reloadVoices() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let french = allVoices.filter { $0.language.lowercased().hasPrefix("fr") }

        let mapped = french.map { voice -> FrenchVoiceInfo in
            let region: String
            if voice.language.contains("FR") || voice.language.contains("fr-FR") {
                region = "France"
            } else if voice.language.contains("CA") || voice.language.contains("fr-CA") {
                region = "Canada"
            } else if voice.language.contains("BE") || voice.language.contains("fr-BE") {
                region = "Belgium"
            } else if voice.language.contains("CH") || voice.language.contains("fr-CH") {
                region = "Switzerland"
            } else {
                region = voice.language
            }
            
            let isEnhanced = voice.quality == .enhanced || voice.quality.rawValue > 1
            return FrenchVoiceInfo(
                id: voice.identifier,
                name: voice.name,
                language: voice.language,
                regionName: region,
                isEnhanced: isEnhanced
            )
        }

        // Sort: France voices first, then enhanced quality, then alphabetical by name
        self.availableFrenchVoices = mapped.sorted { a, b in
            if a.regionName == "France" && b.regionName != "France" { return true }
            if a.regionName != "France" && b.regionName == "France" { return false }
            if a.isEnhanced && !b.isEnhanced { return true }
            if !a.isEnhanced && b.isEnhanced { return false }
            return a.name < b.name
        }

        updateCurrentVoiceInfo()
    }

    /// Updates the cached currentVoiceInfo based on AppSettings
    private func updateCurrentVoiceInfo() {
        if !settings.selectedVoiceIdentifier.isEmpty,
           let found = availableFrenchVoices.first(where: { $0.id == settings.selectedVoiceIdentifier }) {
            currentVoiceInfo = found
            return
        }
        // Default to first France voice or any French voice
        currentVoiceInfo = availableFrenchVoices.first(where: { $0.regionName == "France" }) ?? availableFrenchVoices.first
    }

    /// Selects a specific voice identifier
    func selectVoice(identifier: String) {
        settings.selectedVoiceIdentifier = identifier
        updateCurrentVoiceInfo()
    }

    /// Stops any ongoing speech immediately
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    /// Speaks the given French text
    func speak(text: String, rateMultiplier: Double? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Enforce maximum length protection
        let textToSpeak: String
        if trimmed.count > SpeechService.maxTextLength {
            let index = trimmed.index(trimmed.startIndex, offsetBy: SpeechService.maxTextLength)
            textToSpeak = String(trimmed[..<index]) + "..."
        } else {
            textToSpeak = trimmed
        }

        // Stop any currently playing utterance
        stop()

        let utterance = AVSpeechUtterance(string: textToSpeak)

        // Resolve voice
        if let voice = resolveVoice() {
            utterance.voice = voice
        } else {
            onSpeechError?("No French voice is installed.\nOpen macOS Settings to add a French voice.")
            return
        }

        // Calculate speech rate using a pedagogical non-linear curve.
        // In AVFoundation, 0.5 is normal speed, and linear scaling (e.g. 0.75 * 0.5 = 0.375)
        // is barely distinguishable from normal. This curve ensures 0.75x and 0.5x sound
        // genuinely slow, clear, and distinct for language learners.
        let multiplier = rateMultiplier ?? settings.speechRate
        utterance.rate = SpeechService.effectiveSpeechRate(for: multiplier)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Resolves the AVSpeechSynthesisVoice to use
    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        if !settings.selectedVoiceIdentifier.isEmpty,
           let custom = AVSpeechSynthesisVoice(identifier: settings.selectedVoiceIdentifier) {
            return custom
        }

        // Try standard fr-FR voice
        if let defaultFR = AVSpeechSynthesisVoice(language: "fr-FR") {
            return defaultFR
        }

        // Fallback to any installed French voice
        if let firstInstalled = availableFrenchVoices.first,
           let fallback = AVSpeechSynthesisVoice(identifier: firstInstalled.id) {
            return fallback
        }

        return nil
    }

    /// Pronounce a test sentence to preview selected voice and speed
    func testCurrentVoice(phrase: String = "Bonjour ! Comment allez-vous ?") {
        speak(text: phrase)
    }

    /// Maps human learner speed multipliers to AVFoundation speech rates.
    /// In AVFoundation, rate 0.50 is normal conversational speed.
    /// Linear scaling makes 0.75x sound almost identical to 1.0x.
    /// This mapping creates a distinct, audible difference:
    /// - 0.50x -> 0.18 (very slow, phoneme-by-phoneme enunciation)
    /// - 0.75x -> 0.28 (noticeably slow, clear pedagogical tempo)
    /// - 1.00x -> 0.50 (normal natural French conversational tempo)
    /// - 1.25x -> 0.58 (brisk)
    /// - 1.50x -> 0.66 (fast)
    static func effectiveSpeechRate(for multiplier: Double) -> Float {
        if multiplier <= 0.5 {
            return 0.18
        } else if multiplier <= 0.75 {
            // Smoothly interpolate between 0.5x (0.18) and 0.75x (0.28)
            let t = Float((multiplier - 0.5) / 0.25)
            return 0.18 + t * (0.28 - 0.18)
        } else if multiplier <= 1.0 {
            // Smoothly interpolate between 0.75x (0.28) and 1.0x (0.50)
            let t = Float((multiplier - 0.75) / 0.25)
            return 0.28 + t * (0.50 - 0.28)
        } else if multiplier <= 1.5 {
            // Smoothly interpolate between 1.0x (0.50) and 1.5x (0.66)
            let t = Float((multiplier - 1.0) / 0.5)
            return 0.50 + t * (0.66 - 0.50)
        } else {
            return min(Float(multiplier) * 0.44, AVSpeechUtteranceMaximumSpeechRate)
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.onSpeechCompleted?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
