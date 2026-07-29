import CoreGraphics
import Foundation

/// One of the shortcuts the window server owns, such as Show Desktop.
///
/// These are not ordinary key presses. The window server matches them on the
/// exact combination the user has configured, and both of the ones here carry
/// the fn bit: Show Desktop is fn-F11 and Mission Control is fn-control-Up.
/// Posting F11 or control-Up alone, as this used to, matches nothing and the
/// key press is simply swallowed.
///
/// The combination is also the user's to change, so it is read back from the
/// window server at the moment of use rather than hard-coded. Mac Mouse Fix
/// takes the same route through `CGSGetSymbolicHotKeyValue`.
public enum SymbolicHotKey: Int32 {
    case missionControl = 32
    case showDesktop = 36

    /// The key and modifiers currently bound, or nil when the user has switched
    /// the shortcut off, in which case there is nothing to post.
    public var shortcut: (key: CGKeyCode, flags: CGEventFlags)? {
        guard WindowServer.isEnabled(rawValue) else { return nil }

        var keyEquivalent: UInt16 = 0
        var virtualKey: UInt16 = 0
        var modifiers: UInt32 = 0
        guard WindowServer.value(rawValue, &keyEquivalent, &virtualKey, &modifiers) == 0,
              virtualKey != UInt16.max
        else { return nil }

        // The window server reports modifiers in the same bit layout CGEvent
        // uses, so they carry across unchanged.
        return (CGKeyCode(virtualKey), CGEventFlags(rawValue: UInt64(modifiers)))
    }
}

/// The private window-server calls behind symbolic hot keys.
///
/// SkyLight exports them but publishes no header, so they are resolved by name
/// once and treated as absent if that ever stops working.
private enum WindowServer {
    typealias Value = @convention(c) @Sendable (
        Int32,
        UnsafeMutablePointer<UInt16>,
        UnsafeMutablePointer<UInt16>,
        UnsafeMutablePointer<UInt32>
    ) -> Int32
    typealias Enabled = @convention(c) @Sendable (Int32) -> Bool

    private struct Calls: Sendable {
        let value: Value
        let isEnabled: Enabled
    }

    private static let calls: Calls? = {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY
        ),
            let value = dlsym(handle, "CGSGetSymbolicHotKeyValue"),
            let isEnabled = dlsym(handle, "CGSIsSymbolicHotKeyEnabled")
        else { return nil }

        return Calls(
            value: unsafeBitCast(value, to: Value.self),
            isEnabled: unsafeBitCast(isEnabled, to: Enabled.self)
        )
    }()

    static func value(
        _ id: Int32,
        _ keyEquivalent: UnsafeMutablePointer<UInt16>,
        _ virtualKey: UnsafeMutablePointer<UInt16>,
        _ modifiers: UnsafeMutablePointer<UInt32>
    ) -> Int32 {
        calls?.value(id, keyEquivalent, virtualKey, modifiers) ?? -1
    }

    static func isEnabled(_ id: Int32) -> Bool { calls?.isEnabled(id) ?? false }
}
