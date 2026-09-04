import Foundation
import SwiftUI
import Combine

/// Manages persistent application settings using UserDefaults.
/// Lightweight, zero database, zero external dependencies.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let selectedVoiceIdentifier = "prononce_selected_voice_id"
        static let speechRate = "prononce_speech_rate"
        static let showFloatingPanel = "prononce_show_floating_panel"
        static let hasCompletedOnboarding = "prononce_has_completed_onboarding"
    }

    private let defaults = UserDefaults.standard

    @Published var selectedVoiceIdentifier: String {
        didSet {
            defaults.set(selectedVoiceIdentifier, forKey: Keys.selectedVoiceIdentifier)
        }
    }

    @Published var speechRate: Double {
        didSet {
            defaults.set(speechRate, forKey: Keys.speechRate)
        }
    }

    @Published var showFloatingPanel: Bool {
        didSet {
            defaults.set(showFloatingPanel, forKey: Keys.showFloatingPanel)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    @Published var isLaunchAtLoginEnabled: Bool = false

    private init() {
        self.selectedVoiceIdentifier = defaults.string(forKey: Keys.selectedVoiceIdentifier) ?? ""
        let savedRate = defaults.double(forKey: Keys.speechRate)
        self.speechRate = savedRate > 0 ? savedRate : 1.0
        
        if defaults.object(forKey: Keys.showFloatingPanel) != nil {
            self.showFloatingPanel = defaults.bool(forKey: Keys.showFloatingPanel)
        } else {
            self.showFloatingPanel = true
        }

        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    /// Predefined speed presets for French learners
    static let speedPresets: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5]

    /// Format speed multiplier for display (e.g. "1.0x", "0.75x")
    static func formatSpeed(_ rate: Double) -> String {
        if rate == floor(rate) {
            return String(format: "%.1fx", rate)
        } else {
            return String(format: "%.2gx", rate)
        }
    }
}
