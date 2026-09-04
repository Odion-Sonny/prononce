# Prononce Testing & Verification Checklist

Use this checklist to verify all functionalities of Prononce across applications, edge cases, and performance criteria.

---

## 1. Application-Specific Selection Tests

For each test:
1. Open the designated application.
2. Highlight the sample French text.
3. Press **`⇧⌘F`** (Shift + Command + F).
4. Verify that pronunciation begins immediately and the floating HUD card appears without stealing focus.

### 1.1 Safari
- **Sample Text**: `Bonjour, comment allez-vous aujourd'hui ?`
- **Expected Result**: Spoken clearly in French. Floating HUD appears at the bottom-right. Safari retains cursor focus.
- **Status**: [ ] Pass

### 1.2 Apple Notes / TextEdit
- **Sample Text**: `Je voudrais un croissant et un café s'il vous plaît.`
- **Expected Result**: Spoken clearly in French. Note/Text editor cursor remains in place.
- **Status**: [ ] Pass

### 1.3 Messages / Mail
- **Sample Text**: `C'est une excellente idée, on se voit demain midi.`
- **Expected Result**: Spoken clearly in French.
- **Status**: [ ] Pass

### 1.4 VS Code (Electron App Testing)
- **Sample Text**: `Je suis développeur de logiciels et j'apprends le français.`
- **Expected Result**: Synthetic copy captures selection seamlessly. Previous clipboard content is restored immediately. Spoken in French.
- **Status**: [ ] Pass

### 1.5 PDF Readers (Preview.app)
- **Sample Text**: `La littérature française du dix-neuvième siècle.`
- **Expected Result**: Spoken clearly in French.
- **Status**: [ ] Pass

---

## 2. Speed Controls & Speech Variations

### 2.1 Slow Speed (0.75x & 0.5x)
- Click menu bar icon -> **Speed** -> Select `0.75x`.
- Highlight: `Comment s'est passée ta journée ?`
- Press `⇧⌘F`.
- **Expected Result**: Pronunciation is noticeably slower and clearly articulated, making liaisons and vowels easy to follow.
- **Status**: [ ] Pass

### 2.2 Floating HUD Quick Controls
- While the floating HUD is displayed:
  - Click **🐢 0.75x**: Replays phrase at 0.75x speed (pedagogically slowed down to rate 0.28).
  - Click **1.0x**: Replays phrase at normal speed (rate 0.50).
  - Click **↻ Replay**: Repeats phrase.
  - Click **✕**: Dismisses panel immediately.
- **Status**: [ ] Pass

---

## 3. Voice Selection & Customization

- Open Menu Bar -> **Voice** -> choose an alternate voice (e.g. `Jacques` or `Eddy` or Canadian `Amélie`).
- Highlight: `Bienvenue au cours de français.`
- Press `⇧⌘F`.
- **Expected Result**: Speaks using the newly chosen voice.
- **Status**: [ ] Pass

---

## 4. Edge Cases & Error Handling

### 4.1 No Text Highlighted
- Ensure no text is selected on screen.
- Press `⇧⌘F`.
- **Expected Result**:
  - Subtle system audio alert (`NSSound.beep()`).
  - Floating HUD displays: *"No text selected. Highlight some text and press ⇧⌘F."*
  - No crashes or lingering timers.
- **Status**: [ ] Pass

### 4.2 Large Selection (Protection against freezing)
- Select an extremely long block of text (over 3,000 characters).
- Press `⇧⌘F`.
- **Expected Result**: Text is gracefully capped to 2,500 characters and spoken without freezing the UI or speech engine.
- **Status**: [ ] Pass

### 4.3 Overlapping Hotkey Presses
- Highlight a sentence and press `⇧⌘F`.
- While speech is playing, highlight another sentence and press `⇧⌘F`.
- **Expected Result**: Previous speech terminates immediately; new sentence begins without audio collision.
- **Status**: [ ] Pass

### 4.4 Completely Offline Operation
- Turn off Wi-Fi / disconnect network cables.
- Highlight French text.
- Press `⇧⌘F`.
- **Expected Result**: Pronunciation functions flawlessly using local macOS offline speech engine.
- **Status**: [ ] Pass

---

## 5. Performance & Resource Verification

- Open **Activity Monitor** (`/Applications/Utilities/Activity Monitor.app`).
- Filter for **`Prononce`**.
- Verify:
  - **% CPU while idle**: `0.0%`
  - **Memory (RAM)**: `< 25 MB`
  - **Threads**: Minimal (~4-6 idle threads)
  - **Network / Disk I/O**: `0 bytes`
- **Status**: [ ] Pass
