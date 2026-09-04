import Cocoa
import SwiftUI
#if canImport(Translation)
import Translation

@available(macOS 15.0, *)
private struct TranslationTaskModifier: ViewModifier {
    let config: TranslationSession.Configuration?
    let text: String
    let onComplete: (String) -> Void
    let onError: () -> Void

    func body(content: Content) -> some View {
        content.translationTask(config) { session in
            do {
                let response = try await session.translate(text)
                await MainActor.run {
                    onComplete(response.targetText)
                }
            } catch {
                await MainActor.run {
                    onError()
                }
            }
        }
    }
}
#endif

private extension View {
    @ViewBuilder
    func applyTranslationTask(
        config: Any?,
        text: String,
        onComplete: @escaping (String) -> Void,
        onError: @escaping () -> Void
    ) -> some View {
        #if canImport(Translation)
        if #available(macOS 15.0, *), let translationConfig = config as? TranslationSession.Configuration {
            self.modifier(TranslationTaskModifier(
                config: translationConfig,
                text: text,
                onComplete: onComplete,
                onError: onError
            ))
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// Floating HUD SwiftUI view displaying the captured French phrase, optional translation, and quick controls.
struct FloatingHUDView: View {
    let text: String
    let isError: Bool
    let onReplay: (Double) -> Void
    let onDismiss: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @State private var currentRate: Double = AppSettings.shared.speechRate

    @State private var translatedText: String? = nil
    @State private var isTranslating: Bool = false
    @State private var showTranslation: Bool = false
    @State private var translationConfigHolder: Any? = nil

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

            // Spoken French Text or Notice
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)

            // Translation Section (Automatic or On-Demand)
            if !isError && settings.translationMode != .disabled && showTranslation {
                VStack(alignment: .leading, spacing: 4) {
                    if let translation = translatedText {
                        HStack(alignment: .top, spacing: 6) {
                            Text("💬")
                                .font(.system(size: 11))
                            Text(translation)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else if isTranslating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Translating...")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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

                    // On-Demand Translation Toggle Button
                    if settings.translationMode == .onDemand {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if showTranslation {
                                    showTranslation = false
                                    FloatingHUDPanel.shared.adjustHeightToFit()
                                } else {
                                    showTranslation = true
                                    triggerTranslation()
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))
                                Text(showTranslation ? "Hide" : "Translate")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(showTranslation ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }

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
        .onAppear {
            if settings.translationMode == .automatic && !isError {
                showTranslation = true
                triggerTranslation()
            }
        }
        .applyTranslationTask(
            config: translationConfigHolder,
            text: text,
            onComplete: { targetText in
                self.translatedText = targetText
                self.isTranslating = false
                FloatingHUDPanel.shared.adjustHeightToFit()
                FloatingHUDPanel.shared.restartDismissTimer(duration: 6.0)
            },
            onError: {
                self.isTranslating = false
                if let dictDef = DictionaryService.shared.lookup(phrase: self.text) {
                    self.translatedText = dictDef
                }
                FloatingHUDPanel.shared.adjustHeightToFit()
            }
        )
    }

    private func triggerTranslation() {
        guard translatedText == nil else { return }
        isTranslating = true

        #if canImport(Translation)
        if #available(macOS 15.0, *) {
            if var existing = translationConfigHolder as? TranslationSession.Configuration {
                existing.invalidate()
                translationConfigHolder = existing
            } else {
                translationConfigHolder = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "fr"),
                    target: Locale.Language(identifier: "en")
                )
            }
            return
        }
        #endif

        // Fallback for earlier versions or if translation framework not triggered
        DispatchQueue.global(qos: .userInitiated).async {
            let result = DictionaryService.shared.lookup(phrase: self.text)
            DispatchQueue.main.async {
                self.translatedText = result ?? "No offline translation found"
                self.isTranslating = false
                FloatingHUDPanel.shared.adjustHeightToFit()
            }
        }
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

        let initialDuration: TimeInterval
        if isError {
            initialDuration = 4.5
        } else if AppSettings.shared.translationMode == .automatic {
            initialDuration = 6.0
        } else {
            initialDuration = 3.5
        }

        restartDismissTimer(duration: initialDuration)
    }

    /// Dynamically resizes the panel smoothly when translation appears or disappears
    func adjustHeightToFit() {
        guard let hostingView = self.contentView else { return }
        let newFitting = hostingView.fittingSize
        let newHeight = max(newFitting.height, 100)

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelWidth: CGFloat = 320
            let margin: CGFloat = 24

            let x = screenRect.maxX - panelWidth - margin
            let y = screenRect.minY + margin

            let newFrame = NSRect(x: x, y: y, width: panelWidth, height: newHeight)
            self.setFrame(newFrame, display: true, animate: true)
        }
    }

    func restartDismissTimer(duration: TimeInterval) {
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
