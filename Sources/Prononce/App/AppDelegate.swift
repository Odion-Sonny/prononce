import Cocoa
import SwiftUI

/// Main application lifecycle coordinator
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate?

    private let menuBarController = MenuBarController.shared
    private let hotkeyService = HotkeyService.shared
    private let speechService = SpeechService.shared
    private let selectionService = SelectionService.shared
    private let settings = AppSettings.shared
    private let permissions = PermissionsService.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Ensure app runs as an accessory / menu-bar only utility without Dock icon
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar item
        menuBarController.setup()

        // Setup error callback
        speechService.onSpeechError = { errorMessage in
            FloatingHUDPanel.shared.show(text: errorMessage, isError: true)
        }

        // Setup hotkey listener
        hotkeyService.onHotKeyPressed = { [weak self] in
            self?.triggerPronunciationFlow()
        }
        hotkeyService.register()

        // Check if onboarding or permissions screen is required on launch
        let hasCompleted = settings.hasCompletedOnboarding
        let isTrusted = permissions.checkPermission()

        if !hasCompleted || !isTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                OnboardingWindowController.shared.show()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
        speechService.stop()
    }

    /// Core pronunciation execution flow:
    /// 1. Captures selected text
    /// 2. If empty, plays subtle sound and shows hint
    /// 3. If present, immediately pronounces via AVSpeechSynthesizer and shows HUD
    func triggerPronunciationFlow() {
        selectionService.getSelectedText { [weak self] capturedText in
            guard let self = self else { return }

            guard let text = capturedText, !text.isEmpty else {
                // Subtle feedback for no text selected
                NSSound.beep()
                FloatingHUDPanel.shared.show(
                    text: "No text selected.\nHighlight some text and press ⇧⌘F.",
                    isError: true
                )
                return
            }

            // Speak text using French TTS
            self.speechService.speak(text: text)

            // Show floating pronunciation HUD
            FloatingHUDPanel.shared.show(text: text)
        }
    }
}
