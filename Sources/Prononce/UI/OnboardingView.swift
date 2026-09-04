import SwiftUI
import AppKit

struct OnboardingView: View {
    @ObservedObject private var permissions = PermissionsService.shared
    @ObservedObject private var settings = AppSettings.shared

    let onDismiss: () -> Void

    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            // App Icon / Flag Header
            VStack(spacing: 8) {
                Text("🇫🇷")
                    .font(.system(size: 54))

                Text("Prononce")
                    .font(.title.bold())

                Text("Hear French instantly while you read.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Shortcut Instruction Card
            VStack(spacing: 8) {
                Text("Highlight French text anywhere on your Mac,\nthen press:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    KeyboardKeyView(symbol: "⇧ Shift")
                    Text("+")
                        .foregroundColor(.secondary)
                    KeyboardKeyView(symbol: "⌘ Command")
                    Text("+")
                        .foregroundColor(.secondary)
                    KeyboardKeyView(symbol: "F")
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)

            // Permissions Card
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Permission")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Required so Prononce can read your highlighted text without manual copy/pasting.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if permissions.isAccessibilityGranted {
                        Label("Ready", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13, weight: .semibold))
                    } else {
                        Button("Enable...") {
                            permissions.promptForAccessibility()
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(permissions.isAccessibilityGranted ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
            .cornerRadius(10)

            // Action Button
            Button(action: {
                settings.hasCompletedOnboarding = true
                timer?.invalidate()
                onDismiss()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(width: 420, height: 420)
        .onAppear {
            permissions.checkPermission()
            // Check permission status periodically while onboarding is open
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                permissions.checkPermission()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

/// Window controller for Onboarding window
final class OnboardingWindowController: NSWindowController {
    static let shared = OnboardingWindowController()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Welcome to Prononce"
        window.isReleasedWhenClosed = false
        self.init(window: window)

        window.contentView = NSHostingView(
            rootView: OnboardingView(onDismiss: { [weak self] in
                self?.window?.close()
            })
        )
    }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
