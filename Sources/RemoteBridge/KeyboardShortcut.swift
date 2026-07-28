import AppKit
import Carbon.HIToolbox

/// A recorded key combination.
///
/// Stored as the raw key code plus modifier flags, the way Mac Mouse Fix stores
/// its `keyboardShortcut` action, because that is what has to be posted back.
/// The printable form is derived rather than saved, so it stays correct if the
/// symbols ever change.
struct KeyboardShortcut: Codable, Hashable {
    var keyCode: UInt16
    /// `CGEventFlags` raw value, masked to the modifiers worth persisting.
    var modifiers: UInt64

    static let relevantModifiers: CGEventFlags = [
        .maskCommand, .maskShift, .maskAlternate, .maskControl,
    ]

    init(keyCode: UInt16, modifiers: CGEventFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers.intersection(Self.relevantModifiers).rawValue
    }

    init?(event: NSEvent) {
        guard let flags = event.cgEvent?.flags else { return nil }
        self.init(keyCode: UInt16(event.keyCode), modifiers: flags)
    }

    var eventFlags: CGEventFlags {
        CGEventFlags(rawValue: modifiers).intersection(Self.relevantModifiers)
    }

    /// The usual macOS glyph order: control, option, shift, command.
    var display: String {
        var text = ""
        let flags = eventFlags
        if flags.contains(.maskControl) { text += "⌃" }
        if flags.contains(.maskAlternate) { text += "⌥" }
        if flags.contains(.maskShift) { text += "⇧" }
        if flags.contains(.maskCommand) { text += "⌘" }
        return text + Self.name(for: keyCode)
    }

    /// Names for keys that have no printable character, falling back to the
    /// character the key produces on the current layout.
    private static func name(for keyCode: UInt16) -> String {
        if let special = specialKeys[keyCode] { return special }
        return character(for: keyCode)?.uppercased() ?? "Key \(keyCode)"
    }

    private static let specialKeys: [UInt16: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        76: "⌤", 117: "⌦", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    private static func character(for keyCode: UInt16) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        return data.withUnsafeBytes { buffer -> String? in
            guard let layout = buffer.baseAddress?
                .assumingMemoryBound(to: UCKeyboardLayout.self) else { return nil }

            var deadKeys: UInt32 = 0
            var length = 0
            var characters = [UniChar](repeating: 0, count: 4)

            let status = UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeys,
                characters.count,
                &length,
                &characters
            )
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: characters, count: length)
        }
    }
}
