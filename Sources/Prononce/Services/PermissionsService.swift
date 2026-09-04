import Foundation
import Cocoa
import ApplicationServices

/// Service to query and assist with macOS Accessibility permissions.
final class PermissionsService: ObservableObject {
    static let shared = PermissionsService()

    @Published private(set) var isAccessibilityGranted: Bool = false

    private init() {
        checkPermission()
    }

    /// Checks whether Accessibility is currently trusted for Prononce
    @discardableResult
    func checkPermission() -> Bool {
        let granted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isAccessibilityGranted = granted
        }
        return granted
    }

    /// Prompts macOS system permission prompt for Accessibility
    func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        checkPermission()
    }

    /// Direct deep-link to macOS System Settings -> Privacy & Security -> Accessibility
    func openAccessibilitySettings() {
        // macOS Ventura and newer URL scheme
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Opens macOS Spoken Content / Speech settings so user can download voices
    func openSpeechSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.speech") {
            NSWorkspace.shared.open(url)
        } else if let fallbackUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(fallbackUrl)
        }
    }
}
