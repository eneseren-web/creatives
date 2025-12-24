import Carbon
import Foundation

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?

    func registerToggleHotkey(handler: @escaping () -> Void) {
        let modifierKeys = UInt32(cmdKey | shiftKey | optionKey)
        let hotkeyID = EventHotKeyID(signature: OSType(UInt32(truncatingIfNeeded: "IMDG".fourCharCodeValue)), id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_I), modifierKeys, hotkeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)

        guard status == noErr else { return }

        var eventHandler: EventHandlerRef?
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        InstallEventHandler(GetEventDispatcherTarget(), { _, eventRef, userData in
            guard let eventRef else { return noErr }
            var hotkeyID = EventHotKeyID()
            GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout.size(ofValue: hotkeyID), nil, &hotkeyID)
            if hotkeyID.id == 1 {
                let unmanaged = Unmanaged<HotkeyWrapper>.fromOpaque(userData!)
                unmanaged.takeUnretainedValue().handler()
            }
            return noErr
        }, 1, [eventSpec], UnsafeMutableRawPointer(Unmanaged.passRetained(HotkeyWrapper(handler: handler)).toOpaque()), &eventHandler)
    }
}

private final class HotkeyWrapper {
    let handler: () -> Void
    init(handler: @escaping () -> Void) {
        self.handler = handler
    }
}

private extension String {
    var fourCharCodeValue: Int {
        var result: Int = 0
        for scalar in unicodeScalars {
            result = (result << 8) + Int(scalar.value)
        }
        return result
    }
}
