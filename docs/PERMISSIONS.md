# macOS Permissions Rationale & Guide

Prononce is built with a **privacy-first** design. It requires the absolute minimum system permissions necessary to deliver instant pronunciation without requiring manual copy-pasting.

---

## 1. Required Permission: Accessibility

### Why It Is Needed
When you press `⇧⌘F`, Prononce needs to determine what text is currently highlighted in the frontmost application (e.g. Safari, Mail, Messages, or VS Code).

In macOS, one application cannot inspect the focused UI element or post synthetic shortcut keys to another application without explicit **Accessibility** permission granted by the user.

### What Prononce Does With Accessibility
- Reads the selected text attribute (`kAXSelectedTextAttribute`) of the focused element.
- If the application is non-native (e.g. Electron/Chrome), generates a momentary synthetic `Command+C` key event to read the selection, and **immediately restores your previous clipboard**.

### What Prononce DOES NOT Do
- ❌ Does **not** record keystrokes or password entries.
- ❌ Does **not** monitor your screen or take screenshots.
- ❌ Does **not** poll your clipboard in the background.
- ❌ Does **not** send any text to the internet or any third-party server.
- ❌ Does **not** store a history of what you highlighted.

All processing occurs strictly in local Mac memory at the exact instant you press `⇧⌘F`.

---

## 2. Enabling Accessibility Permission

### Option A: From Prononce's First-Run Screen
1. Launch Prononce (`open build/Prononce.app`).
2. The welcome screen will indicate if Accessibility is not yet granted.
3. Click **"Enable..."** or **"Grant Permission"**.
4. Prononce will open **System Settings → Privacy & Security → Accessibility**.
5. Toggle **Prononce** to **ON** (enter your Mac password or Touch ID if prompted).
6. Return to Prononce; the status will update to **Ready** in real-time.

### Option B: Manual Setup via macOS System Settings
1. Open **System Settings** on your Mac.
2. Navigate to **Privacy & Security** in the sidebar.
3. Select **Accessibility** from the list of permissions.
4. If Prononce appears in the list, toggle the switch to **ON**.
5. If Prononce is not in the list, click the **`+`** button, navigate to `/Applications` or the location where `Prononce.app` is installed, and select it.

---

## 3. Revoking Permission

You may revoke permission at any time:
1. Open **System Settings → Privacy & Security → Accessibility**.
2. Toggle Prononce **OFF** or select it and click the **`-`** button.
