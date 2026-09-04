import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var speechService = SpeechService.shared
    @ObservedObject private var permissions = PermissionsService.shared

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)

            voiceTab
                .tabItem {
                    Label("Voice", systemImage: "waveform")
                }
                .tag(1)

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
        .frame(width: 480, height: 340)
        .padding(20)
        .onAppear {
            permissions.checkPermission()
            speechService.reloadVoices()
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                // Global Shortcut Display
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    HStack(spacing: 4) {
                        KeyboardKeyView(symbol: "⇧")
                        KeyboardKeyView(symbol: "⌘")
                        KeyboardKeyView(symbol: "F")
                    }
                }
                .padding(.vertical, 4)

                // Floating Panel Toggle
                Toggle("Show floating pronunciation panel", isOn: $settings.showFloatingPanel)
                    .help("Shows a temporary panel with replay controls after pronouncing text")

                // Launch at Login
                Toggle("Launch Prononce at login", isOn: Binding(
                    get: { LaunchAtLoginService.shared.isEnabled },
                    set: { enabled in
                        LaunchAtLoginService.shared.setEnabled(enabled)
                        settings.isLaunchAtLoginEnabled = enabled
                    }
                ))
            } header: {
                Text("Behavior")
                    .font(.headline)
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Permission")
                            .font(.body)
                        Text(permissions.isAccessibilityGranted ? "Granted — Prononce can read highlighted text." : "Required for capturing text automatically.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if permissions.isAccessibilityGranted {
                        Label("Enabled", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    } else {
                        Button("Grant Permission") {
                            permissions.promptForAccessibility()
                            permissions.openAccessibilitySettings()
                        }
                    }
                }
            } header: {
                Text("System Permissions")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Voice Tab

    private var voiceTab: some View {
        Form {
            Section {
                if speechService.availableFrenchVoices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No French voices detected on your Mac.")
                            .foregroundColor(.red)
                        Button("Open macOS Speech Settings") {
                            permissions.openSpeechSettings()
                        }
                    }
                } else {
                    Picker("French Voice", selection: Binding(
                        get: { settings.selectedVoiceIdentifier },
                        set: { newId in
                            speechService.selectVoice(identifier: newId)
                        }
                    )) {
                        ForEach(speechService.availableFrenchVoices) { voice in
                            Text("\(voice.displayName) (\(voice.regionName))")
                                .tag(voice.id)
                        }
                    }

                    // Speed controls
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Pronunciation Speed")
                            Spacer()
                            Text(AppSettings.formatSpeed(settings.speechRate))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        HStack(spacing: 8) {
                            ForEach(AppSettings.speedPresets, id: \.self) { preset in
                                Button(action: {
                                    settings.speechRate = preset
                                }) {
                                    Text(AppSettings.formatSpeed(preset))
                                        .font(.system(size: 11, weight: settings.speechRate == preset ? .bold : .regular))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(settings.speechRate == preset ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Test Voice button
                    HStack {
                        Spacer()
                        Button(action: {
                            speechService.testCurrentVoice()
                        }) {
                            Label(speechService.isSpeaking ? "Speaking..." : "Test Voice", systemImage: "speaker.wave.2")
                        }
                        .disabled(speechService.isSpeaking)
                    }
                }
            } header: {
                Text("Speech Synthesis")
                    .font(.headline)
            } footer: {
                Text("Prononce uses Apple's native high-quality speech engine completely offline.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("🇫🇷")
                .font(.system(size: 48))

            VStack(spacing: 4) {
                Text("Prononce")
                    .font(.title2.bold())
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("A lightweight native French pronunciation tool for macOS.\nInstant, private, and offline.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 40)

            VStack(spacing: 4) {
                Label("100% On-Device & Private", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundColor(.green)
                Text("Zero data collection. Zero cloud calls. Zero background polling.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

/// Simple styled keyboard key for displaying shortcuts
struct KeyboardKeyView: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
            )
    }
}

/// Window controller to present the native Settings window
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Prononce Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
