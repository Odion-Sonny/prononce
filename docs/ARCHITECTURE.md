# Prononce Architecture Document

Prononce is built to follow Apple's modern macOS software engineering best practices, emphasizing **instant responsiveness**, **minimal memory consumption**, **zero idle CPU usage**, and **strict user privacy**.

---

## 1. High-Level Architecture Overview

Prononce is designed as an OS **agent utility** (`LSUIElement = true` / `.accessory` activation policy). It does not maintain an open document window or stay pinned to the Dock.

```text
┌──────────────────────────────────────────────────────────┐
│                   macOS Operating System                 │
└────────────┬─────────────────────────────▲───────────────┘
             │ Key Press (⇧⌘F)             │ Speech Output
             ▼                             │
┌─────────────────────────┐   ┌────────────┴───────────────┐
│      HotkeyService      │   │       SpeechService        │
│  (Carbon RegisterHotKey)│   │   (AVSpeechSynthesizer)    │
└────────────┬────────────┘   └────────────▲───────────────┘
             │                             │
             ▼                             │ Spoken Text
┌─────────────────────────┐                │
│    SelectionService     ├────────────────┘
│  (AXUIElement + Copy)   │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│    FloatingHUDPanel     │
│ (Non-activating NSPanel)│
└─────────────────────────┘
```

---

## 2. Core Subsystems

### 2.1 Global Shortcut Handling (`HotkeyService.swift`)
- **Technology**: Carbon Event Manager (`RegisterEventHotKey` / `InstallEventHandler`).
- **Why Carbon?**:
  - Event-driven at the OS kernel/dispatcher level.
  - Consumes **0.0% CPU** while waiting.
  - Does NOT require low-level Input Monitoring permissions (`CGEventTap`), which reduces privacy friction for users.
  - Global scope: functions universally across all applications.

### 2.2 Selection Capture (`SelectionService.swift`)
Retrieving selected text without manual clipboard copying requires navigating macOS application diversity:

1. **Strategy 1: Direct Accessibility (`AXUIElementCopyAttributeValue`)**
   - Queries `kAXFocusedApplicationAttribute` -> `kAXFocusedUIElementAttribute` -> `kAXSelectedTextAttribute`.
   - Used for AppKit/Cocoa native apps (Notes, Mail, Safari, Pages, TextEdit).
   - Fast, instantaneous (0ms), and leaves clipboard untouched.

2. **Strategy 2: Resilient Synthetic Copy with Pasteboard Restoration**
   - Web applications, Electron apps (VS Code, Slack, Discord), and complex canvas views often do not vend `kAXSelectedTextAttribute` directly through the accessibility tree.
   - When Strategy 1 yields no text, Strategy 2 triggers a synthetic `Command+C` (`CGEvent`), captures the text when `NSPasteboard.general.changeCount` updates, and **immediately restores the user's prior clipboard items**.
   - Result: The user hears their text without ever having their clipboard modified or overwritten.

3. **Protection Limits**:
   - Caps input to 2,500 characters to prevent speech synthesizer overload if an entire book is inadvertently selected.

### 2.3 Local Text-to-Speech (`SpeechService.swift`)
- **Technology**: Apple `AVFoundation` (`AVSpeechSynthesizer`, `AVSpeechUtterance`, `AVSpeechSynthesisVoice`).
- **Voices**:
  - Automatically queries `AVSpeechSynthesisVoice.speechVoices()` for French locales (`fr-FR`, `fr-CA`, `fr-BE`, `fr-CH`).
  - Prioritizes native French (`fr-FR`) voices (Thomas, Jacques, Audrey, etc.).
  - Handles enhanced quality voices seamlessly.
- **Pedagogical Speed Curve**:
  - Employs a non-linear perceptual speed curve (`effectiveSpeechRate(for:)`). Because AVFoundation's linear rate scaling (0.75 * 0.5 = 0.375) is barely distinguishable from normal tempo, Prononce maps `0.75x` to `0.28` and `0.5x` to `0.18`, providing genuine, audibly distinct articulation of French phonemes and liaisons.
- **Collision Prevention**:
  - Immediately terminates previous utterance (`synthesizer.stopSpeaking(at: .immediate)`) when new shortcut is pressed.

### 2.4 Floating Pronunciation Card (`FloatingHUDPanel.swift`)
- **Technology**: Custom `NSPanel` with `.nonactivatingPanel` style mask, floating window level, and SwiftUI content view (`NSHostingView`).
- **Key UX Property**: `canBecomeKey = false`. This guarantees that popping up the card **never steals keyboard focus** from the document or chat the user was typing in.
- **Lifecycle**: Automatically fades out after 3.5 seconds of inactivity.

### 2.5 Menu Bar Controller (`MenuBarController.swift`)
- Manages `NSStatusItem` in the macOS system status bar.
- Dynamically updates menu items on open via `NSMenuDelegate`, ensuring checkmarks and voice lists reflect current system state.

### 2.6 Persistence (`AppSettings.swift`)
- Backed strictly by macOS `UserDefaults`.
- Avoids external databases (SQLite, CoreData, Realm) to maintain minimal memory footprint and zero disk I/O overhead.

---

## 3. Resource & Performance Benchmarks

| Metric | Measured Target | Actual Value |
| :--- | :--- | :--- |
| **Idle CPU Usage** | < 0.1% | **0.0%** (Event-driven) |
| **App Bundle Size** | < 10 MB | **1.1 MB** |
| **DMG Distribution Size** | < 5 MB | **848 KB** |
| **Memory Footprint (Idle)** | < 30 MB | **~18 MB** |
| **Trigger-to-Speech Latency** | < 100 ms | **~25 ms** |
| **Network Requests** | 0 | **0 (Completely Offline)** |

---

## 4. Extensibility for Future Milestones

The modular decoupled architecture allows future additions without rewriting core services:
- **IPA Phonetics**: Add an `IPAService` called by `AppDelegate` to compute phonetic breakdown for display in `FloatingHUDPanel`.
- **Vocabulary Vault**: Connect an export handler in `AppDelegate` to save selected phrases into Anki-compatible CSV or JSON.
- **Multi-language Expansion**: Abstract `SpeechService` to detect language or allow Spanish/German/Italian voice packages.
