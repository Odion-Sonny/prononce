import Foundation
import AppKit
import Carbon
import ApplicationServices

/// Reliable, lightweight service to capture highlighted text from the frontmost application.
/// Uses a dual-strategy:
/// 1. Native Accessibility API (AXUIElement) - Instant, zero clipboard side-effects.
/// 2. Synthetic Command+C fallback with automatic pasteboard restoration for non-AX apps (VS Code, Chrome, etc.).
final class SelectionService {
    static let shared = SelectionService()

    private init() {}

    /// Retrieves the currently selected text across any macOS application.
    /// Runs on a background thread to prevent UI blocking when waiting for clipboard fallback.
    func getSelectedText(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            // Strategy 1: Try Accessibility API first
            if let axText = self.captureViaAccessibility(), !axText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let cleaned = self.cleanText(axText)
                DispatchQueue.main.async {
                    completion(cleaned)
                }
                return
            }

            // Strategy 2: Fallback to synthetic Command+C with clipboard preservation
            self.captureViaSyntheticCopy { copiedText in
                let cleaned = copiedText.flatMap { self.cleanText($0) }
                DispatchQueue.main.async {
                    completion(cleaned)
                }
            }
        }
    }

    // MARK: - Strategy 1: Accessibility API

    private func captureViaAccessibility() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppValue: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppValue)
        guard appResult == .success, let focusedApp = focusedAppValue else {
            return nil
        }

        var focusedElementValue: AnyObject?
        let elemResult = AXUIElementCopyAttributeValue(focusedApp as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElementValue)
        guard elemResult == .success, let focusedElement = focusedElementValue else {
            return nil
        }

        var selectedTextValue: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedTextValue)
        if textResult == .success, let text = selectedTextValue as? String, !text.isEmpty {
            return text
        }

        return nil
    }

    // MARK: - Strategy 2: Synthetic Command+C with Pasteboard Restore

    /// Structure to hold backed up pasteboard data
    private struct SavedPasteboardItem {
        let entries: [(NSPasteboard.PasteboardType, Data)]
    }

    private func captureViaSyntheticCopy(completion: @escaping (String?) -> Void) {
        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount

        // 1. Back up existing clipboard contents
        let savedItems: [SavedPasteboardItem] = (pasteboard.pasteboardItems ?? []).map { item in
            var entries: [(NSPasteboard.PasteboardType, Data)] = []
            for type in item.types {
                if let data = item.data(forType: type) {
                    entries.append((type, data))
                }
            }
            return SavedPasteboardItem(entries: entries)
        }

        // 2. Synthesize Command+C (virtualKey 0x08 = 'c')
        let src = CGEventSource(stateID: .combinedSessionState)
        let keyC: CGKeyCode = 0x08 // kVK_ANSI_C

        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyC, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyC, keyDown: false) else {
            completion(nil)
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        // 3. Wait briefly for pasteboard to update (up to 150ms)
        var capturedText: String? = nil
        let pollInterval = 0.015 // 15ms
        let maxWait = 0.150 // 150ms
        var waited = 0.0

        while waited < maxWait {
            Thread.sleep(forTimeInterval: pollInterval)
            waited += pollInterval

            if pasteboard.changeCount != initialChangeCount {
                // Clipboard updated with selection
                if let str = pasteboard.string(forType: .string) {
                    capturedText = str
                }
                break
            }
        }

        // 4. Restore original clipboard contents immediately
        if !savedItems.isEmpty {
            pasteboard.clearContents()
            var restoredObjects: [NSPasteboardItem] = []
            for saved in savedItems {
                let item = NSPasteboardItem()
                for (type, data) in saved.entries {
                    item.setData(data, forType: type)
                }
                restoredObjects.append(item)
            }
            pasteboard.writeObjects(restoredObjects)
        } else if capturedText != nil {
            // Original clipboard was empty, clear the temp copy
            pasteboard.clearContents()
        }

        completion(capturedText)
    }

    // MARK: - Helpers

    private func cleanText(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Truncate if exceptionally large to avoid TTS memory overload
        if trimmed.count > SpeechService.maxTextLength {
            let index = trimmed.index(trimmed.startIndex, offsetBy: SpeechService.maxTextLength)
            return String(trimmed[..<index])
        }

        return trimmed
    }
}
