import Cocoa
import SwiftUI

/// Controller for the macOS menu bar icon (NSStatusItem) and its dynamic menu.
final class MenuBarController: NSObject, NSMenuDelegate {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let settings = AppSettings.shared
    private let speechService = SpeechService.shared
    private let launchService = LaunchAtLoginService.shared

    override private init() {
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Using a clean French flag representation
            button.title = "🇫🇷"
            button.toolTip = "Prononce — Instant French Pronunciation (⇧⌘F)"
            button.imagePosition = .imageLeading
        }

        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    // MARK: - Menu Construction

    func rebuildMenu() {
        menu.removeAllItems()

        // App Title / Header
        let titleItem = NSMenuItem(title: "Prononce (1.0.0)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Speak Selected Text action
        let speakItem = NSMenuItem(
            title: "Speak Selected Text",
            action: #selector(speakSelectedTextAction),
            keyEquivalent: "F"
        )
        speakItem.keyEquivalentModifierMask = [.shift, .command]
        speakItem.target = self
        menu.addItem(speakItem)

        menu.addItem(NSMenuItem.separator())

        // Voice Submenu
        let voiceItem = NSMenuItem(title: "Voice", action: nil, keyEquivalent: "")
        let voiceSubmenu = NSMenu()
        populateVoiceSubmenu(voiceSubmenu)
        voiceItem.submenu = voiceSubmenu
        menu.addItem(voiceItem)

        // Speed Submenu
        let speedItem = NSMenuItem(title: "Speed", action: nil, keyEquivalent: "")
        let speedSubmenu = NSMenu()
        populateSpeedSubmenu(speedSubmenu)
        speedItem.submenu = speedSubmenu
        menu.addItem(speedItem)

        // Translation Submenu
        let translationItem = NSMenuItem(title: "Translation", action: nil, keyEquivalent: "")
        let translationSubmenu = NSMenu()
        populateTranslationSubmenu(translationSubmenu)
        translationItem.submenu = translationSubmenu
        menu.addItem(translationItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login Toggle
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchService.isEnabled ? .on : .off
        menu.addItem(launchItem)

        // Floating Panel Toggle
        let panelItem = NSMenuItem(
            title: "Show Floating Panel",
            action: #selector(toggleFloatingPanel),
            keyEquivalent: ""
        )
        panelItem.target = self
        panelItem.state = settings.showFloatingPanel ? .on : .off
        menu.addItem(panelItem)

        menu.addItem(NSMenuItem.separator())

        // Settings...
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Check Permissions...
        let permItem = NSMenuItem(
            title: "Check Permissions...",
            action: #selector(checkPermissionsAction),
            keyEquivalent: ""
        )
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())

        // Quit Prononce
        let quitItem = NSMenuItem(
            title: "Quit Prononce",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func populateVoiceSubmenu(_ submenu: NSMenu) {
        let voices = speechService.availableFrenchVoices
        let currentId = speechService.currentVoiceInfo?.id ?? ""

        if voices.isEmpty {
            let emptyItem = NSMenuItem(title: "No French Voice Found", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)

            let downloadItem = NSMenuItem(title: "Add Voice in System Settings...", action: #selector(openSpeechSettings), keyEquivalent: "")
            downloadItem.target = self
            submenu.addItem(downloadItem)
            return
        }

        // France voices
        let franceVoices = voices.filter { $0.regionName == "France" }
        if !franceVoices.isEmpty {
            let header = NSMenuItem(title: "French (France)", action: nil, keyEquivalent: "")
            header.isEnabled = false
            submenu.addItem(header)

            for voice in franceVoices {
                let item = NSMenuItem(title: "  \(voice.displayName)", action: #selector(selectVoiceAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = voice.id
                item.state = (voice.id == currentId) ? .on : .off
                submenu.addItem(item)
            }
        }

        // Other French voices (Canada, Belgium, etc.)
        let otherVoices = voices.filter { $0.regionName != "France" }
        if !otherVoices.isEmpty {
            if !franceVoices.isEmpty {
                submenu.addItem(NSMenuItem.separator())
            }

            let header = NSMenuItem(title: "French (Regional / Canada)", action: nil, keyEquivalent: "")
            header.isEnabled = false
            submenu.addItem(header)

            for voice in otherVoices {
                let item = NSMenuItem(title: "  \(voice.displayName) (\(voice.regionName))", action: #selector(selectVoiceAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = voice.id
                item.state = (voice.id == currentId) ? .on : .off
                submenu.addItem(item)
            }
        }
    }

    private func populateSpeedSubmenu(_ submenu: NSMenu) {
        for preset in AppSettings.speedPresets {
            let item = NSMenuItem(
                title: AppSettings.formatSpeed(preset),
                action: #selector(selectSpeedAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = preset
            item.state = (abs(settings.speechRate - preset) < 0.01) ? .on : .off
            submenu.addItem(item)
        }
    }

    private func populateTranslationSubmenu(_ submenu: NSMenu) {
        for mode in AppSettings.TranslationMode.allCases {
            let item = NSMenuItem(
                title: mode.displayName,
                action: #selector(selectTranslationModeAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode
            item.state = (settings.translationMode == mode) ? .on : .off
            submenu.addItem(item)
        }
    }

    // MARK: - Actions

    @objc private func selectTranslationModeAction(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? AppSettings.TranslationMode {
            settings.translationMode = mode
            rebuildMenu()
        }
    }

    @objc private func speakSelectedTextAction() {
        AppDelegate.shared?.triggerPronunciationFlow()
    }

    @objc private func selectVoiceAction(_ sender: NSMenuItem) {
        if let voiceId = sender.representedObject as? String {
            speechService.selectVoice(identifier: voiceId)
            rebuildMenu()
        }
    }

    @objc private func selectSpeedAction(_ sender: NSMenuItem) {
        if let speed = sender.representedObject as? Double {
            settings.speechRate = speed
            rebuildMenu()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let newState = !launchService.isEnabled
        launchService.setEnabled(newState)
        settings.isLaunchAtLoginEnabled = newState
        rebuildMenu()
    }

    @objc private func toggleFloatingPanel() {
        settings.showFloatingPanel.toggle()
        rebuildMenu()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func checkPermissionsAction() {
        OnboardingWindowController.shared.show()
    }

    @objc private func openSpeechSettings() {
        PermissionsService.shared.openSpeechSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
