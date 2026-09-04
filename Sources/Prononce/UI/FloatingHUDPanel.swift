import Cocoa
import SwiftUI

/// Floating HUD SwiftUI view displaying the captured French phrase and quick controls.
struct FloatingHUDView: View {
    let text: String
    let isError: Bool
    let onReplay: (Double) -> Void
    let onDismiss: () -> Void

    @State private var currentRate: Double = AppSettings.shared.speechRate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("🇫🇷")
                        .font(.system(size: 14))
                    Text(isError ? "Prononce" : "French")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Spoken Text or Notice
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)

            // Controls (only shown if not an error message)
            if !isError {
                HStack(spacing: 8) {
                    Button(action: {
                        onReplay(currentRate)
                    }) {
                        Label("Replay", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        currentRate = 0.75
                        onReplay(0.75)
                    }) {
                        Text("🐢 0.75x")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(currentRate == 0.75 ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        currentRate = 1.0
                        onReplay(1.0)
                    }) {
                        Text("1.0x")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(currentRate == 1.0 ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

/// Custom non-activating floating panel that never steals keyboard focus.
final class FloatingHUDPanel: NSPanel {
    static let shared = FloatingHUDPanel()

    private var dismissTimer: Timer?
    private var isHovered: Bool = false

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }

    /// Shows the panel with the given text and sets up auto-dismiss
    func show(text: String, isError: Bool = false) {
        guard AppSettings.shared.showFloatingPanel || isError else { return }

        dismissTimer?.invalidate()

        let hudView = FloatingHUDView(
            text: text,
            isError: isError,
            onReplay: { rate in
                SpeechService.shared.speak(text: text, rateMultiplier: rate)
                self.restartDismissTimer(duration: 4.0)
            },
            onDismiss: {
                self.dismissAnimated()
            }
        )

        let hostingView = NSHostingView(rootView: hudView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: hostingView.fittingSize.height)
        self.contentView = hostingView
        self.setContentSize(hostingView.fittingSize)

        // Position panel at bottom right of the main screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelWidth: CGFloat = 320
            let margin: CGFloat = 24

            let x = screenRect.maxX - panelWidth - margin
            let y = screenRect.minY + margin

            self.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.alphaValue = 0.0
        self.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1.0
        }

        restartDismissTimer(duration: isError ? 4.5 : 3.5)
    }

    private func restartDismissTimer(duration: TimeInterval) {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self, !self.isHovered else { return }
            self.dismissAnimated()
        }
    }

    func dismissAnimated() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
}
