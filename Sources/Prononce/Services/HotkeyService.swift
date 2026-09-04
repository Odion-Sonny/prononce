import Foundation
import Carbon

/// Low-level Carbon global hotkey manager for Option + Command + F (⌥⌘F).
/// Event-driven, consumes zero CPU cycles while idle, requires zero polling.
final class HotkeyService {
    static let shared = HotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    /// Callback invoked when ⌥⌘F is pressed globally
    var onHotKeyPressed: (() -> Void)?

    private let hotKeyID = EventHotKeyID(signature: OSType(0x50524F4E), id: 1) // 'PRON'

    private init() {}

    deinit {
        unregister()
    }

    /// Registers the global shortcut ⌥⌘F
    @discardableResult
    func register() -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr && hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    service.onHotKeyPressed?()
                }
            }

            return noErr
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            print("Prononce: Failed to install Carbon event handler: \(installStatus)")
            return false
        }

        // Key code for 'F' is 3 (kVK_ANSI_F)
        let keyCodeF: UInt32 = 0x03
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        let regStatus = RegisterEventHotKey(
            keyCodeF,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard regStatus == noErr else {
            print("Prononce: Failed to register hotkey ⇧⌘F: \(regStatus)")
            return false
        }

        print("Prononce: Successfully registered global shortcut ⇧⌘F (Shift+Command+F)")
        return true
    }

    /// Unregisters the hotkey
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}
