import AppKit
import Carbon.HIToolbox

/// Registers a global system hotkey using Carbon's RegisterEventHotKey.
///
/// We use Carbon (long deprecated, still functional and the only public API
/// for global hotkeys without Accessibility permission) so this app can stay
/// dependency-free and sandbox-clean per D-002. The default binding is ⌘⇧V.
@MainActor
final class HotkeyManager {
    typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let handler: Handler

    // ⌘⇧V — V is keycode 9, modifiers are cmd+shift.
    private let keyCode: UInt32 = UInt32(kVK_ANSI_V)
    private let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    private let signature: OSType = OSType(0x434C5053) // 'CLPS'
    private let hotKeyID: UInt32 = 1

    init(handler: @escaping Handler) {
        self.handler = handler
        registerHandler()
        registerHotkey()
    }

    deinit {
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
        }
        if let eh = eventHandler {
            RemoveEventHandler(eh)
        }
    }

    private func registerHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Pass `self` through as user data so the C callback can call back into us.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let userData = userData, let eventRef = eventRef else {
                    return noErr
                }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if status == noErr {
                    Task { @MainActor in
                        manager.handler()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func registerHotkey() {
        let hkID = EventHotKeyID(signature: signature, id: hotKeyID)
        RegisterEventHotKey(keyCode, modifiers, hkID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
