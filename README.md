# 🇫🇷 Prononce

> **Instant, lightweight native macOS French pronunciation utility for learners.**

Highlight French text anywhere on your Mac, press **`⇧⌘F`** (Shift + Command + F), and immediately hear native French pronunciation powered by Apple's built-in speech engine.

No copying. No pasting. No Electron. No subscriptions. No cloud latency. 100% offline and private.

---

## Key Features

- **Instant Global Shortcut (`⇧⌘F`)**: Select French text in Safari, Chrome, Mail, Messages, Notes, VS Code, Slack, or PDFs, press the hotkey, and listen immediately.
- **Zero-Polling Selection Capture**: Uses native macOS Accessibility (`AXUIElement`) with a resilient synthetic copy fallback that **instantly restores your prior clipboard contents**—your clipboard is never overwritten.
- **Apple Native High-Quality Voices**: Leverages `AVSpeechSynthesizer` with local French voices (`fr-FR`, `fr-CA`, etc.) installed on macOS.
- **Learner-Optimized Playback Speed**: Choose from **0.5x**, **0.75x**, **1.0x**, **1.25x**, or **1.5x**—with a calibrated pedagogical speed curve making **0.75x** and **0.5x** noticeably slow, clear, and easy to follow.
- **Floating Pronunciation HUD**: A sleek, non-activating floating card displays the spoken text with instant **↻ Replay** and speed controls. It auto-dismisses after a few seconds and never steals keyboard focus.
- **Local On-Device English Translation**: Displays immediate French-to-English translation directly in the floating card using Apple's built-in `Translation` framework and Dictionary services. Toggle between **Automatic**, **On-Demand**, or **Off** via Menu Bar or Settings with 100% offline privacy.
- **Menu Bar Utility**: Runs quietly in the menu bar with zero Dock clutter (`LSUIElement`).
- **Tiny Footprint**:
  - Binary size: ~**1.3 MB**
  - DMG installer: ~**900 KB**
  - Idle CPU usage: **0.0%** (zero polling, fully event-driven)
- **Launch at Login**: Native macOS 13+ `SMAppService` integration.
- **100% Offline & Private**: Zero analytics, zero accounts, zero cloud requests, zero data storage.

---

## System Requirements

- **macOS 13.0 (Ventura)** or later (including Sonoma and Sequoia).
- Apple Silicon (M1/M2/M3/M4) or Intel Mac.

---

## Quick Start

### 1. Build and Run the App Bundle

Clone the repository and run the automated build script:

```bash
# Build the self-contained Release .app bundle
./scripts/build_app.sh

# Launch Prononce
open build/Prononce.app
```

### 2. Build a Distributable `.dmg`

To package a standalone drag-and-drop `.dmg` installer:

```bash
./scripts/create_dmg.sh
```

The resulting `build/Prononce.dmg` can be distributed directly to users.

### 3. Open in Xcode

You can open the project in Xcode either directly or through the package:

```bash
open Prononce.xcodeproj
# OR
open Package.swift
```

---

## How It Works

```text
User highlights French text
           ↓
   Presses ⇧⌘F
           ↓
Carbon Event Dispatcher (0% idle CPU)
           ↓
SelectionService captures selected text:
  1. Tries AXUIElement (Instant, no pasteboard touch)
  2. If needed: Fast synthetic ⌘C + immediate pasteboard restore
           ↓
AVSpeechSynthesizer speaks text in French (fr-FR)
           ↓
Non-activating FloatingHUD appears briefly (Auto-dismisses in 3.5s)
```

---

## Required macOS Permissions

Prononce requires **Accessibility** permission to read the currently highlighted text when you trigger the shortcut.

1. On first launch, Prononce presents a welcome screen guiding you through the permission step.
2. Alternatively, open **System Settings → Privacy & Security → Accessibility** and ensure **Prononce** is toggled **ON**.

See [`docs/PERMISSIONS.md`](docs/PERMISSIONS.md) for details on why this permission is needed and how your privacy is protected.

---

## Usage Guide

### Menu Bar Controls

Click the **🇫🇷** icon in the macOS menu bar to access:

- **Speak Selected Text (`⇧⌘F`)**: Manually trigger pronunciation.
- **Voice**: Choose between installed French voices (France: Thomas, Jacques, Audrey, etc.; Canada: Amélie, etc.).
- **Speed**: Select playback rate (`0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`).
- **Translation**: Switch between `Automatic`, `On-Demand`, or `Off`.
- **Launch at Login**: Enable or disable automatic startup.
- **Show Floating Panel**: Toggle the floating HUD card.
- **Settings... (`⌘,`)**: Open the native preferences window.
- **Quit (`⌘Q`)**: Terminate Prononce.

### Floating Pronunciation HUD

When text is spoken, a floating card appears in the lower-right screen corner:
- **Spoken Text**: Displays the captured phrase.
- **↻ Replay**: Re-pronounces the phrase.
- **🐢 0.75x**: Pronounces the phrase slowly for difficult vowel sounds and liaisons.
- **1.0x**: Pronounces at natural native speed.
- **✕**: Dismisses immediately.

---

## Architecture & Codebase

```text
prononce/
├── Package.swift                    # Swift Package Manager definition
├── Prononce.xcodeproj/              # Native Xcode project
├── Sources/Prononce/
│   ├── App/
│   │   ├── PrononceApp.swift        # Main entry point (@main)
│   │   └── AppDelegate.swift        # Lifecycle & shortcut coordinator
│   ├── Services/
│   │   ├── SpeechService.swift      # AVSpeechSynthesizer manager & voice catalogue
│   │   ├── SelectionService.swift   # Hybrid AX + clipboard-preserving text capture
│   │   ├── HotkeyService.swift      # Low-level Carbon RegisterEventHotKey wrapper
│   │   ├── PermissionsService.swift # Accessibility permission detection & deep links
│   │   └── LaunchAtLoginService.swift # macOS 13+ SMAppService wrapper
│   ├── Models/
│   │   └── AppSettings.swift        # UserDefaults-backed observable preferences
│   └── UI/
│       ├── MenuBarController.swift  # Status bar item & dynamic NSMenu
│       ├── FloatingHUDPanel.swift   # Non-activating floating panel & SwiftUI card
│       ├── SettingsView.swift       # Native SwiftUI preferences window
│       └── OnboardingView.swift     # First-run welcome & permission sheet
├── Resources/
│   ├── Info.plist                   # LSUIElement=true, bundle configuration
│   └── AppIcon.icns                 # High-resolution Retina icon
└── scripts/
    ├── build_app.sh                 # Compiles & packages Prononce.app
    ├── create_dmg.sh                # Generates distributable Prononce.dmg
    └── generate_icon.sh             # Generates AppIcon.icns from vector script
```

For in-depth architectural decisions, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Testing & Quality Assurance

See [`docs/TESTING_CHECKLIST.md`](docs/TESTING_CHECKLIST.md) for step-by-step verification across Safari, Chrome, VS Code, Messages, offline mode, and idle resource benchmarks.

---

## License

MIT License. Designed with visual elegance and engineering discipline for macOS.
