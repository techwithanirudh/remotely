import CoreGraphics

/// Reads the user's current window-server shortcut, including the fn bit.
/// Hard-coded F11 or control-Up events are swallowed when they do not match.
public enum SymbolicHotKey: Int32 {
    case missionControl = 32
    case showDesktop = 36

    /// The key and modifiers currently bound, or nil when the user has switched
    /// the shortcut off, in which case there is nothing to post.
    public var shortcut: (key: CGKeyCode, flags: CGEventFlags)? {
        guard WindowServer.isEnabled(rawValue) else { return nil }

        var equivalent: UInt16 = 0
        var key: UInt16 = 0
        var flags: UInt32 = 0
        guard WindowServer.value(rawValue, &equivalent, &key, &flags) == 0,
              key != UInt16.max
        else { return nil }

        // The window server reports modifiers in the same bit layout CGEvent
        // uses, so they carry across unchanged.
        return (CGKeyCode(key), CGEventFlags(rawValue: UInt64(flags)))
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
        _ equivalent: UnsafeMutablePointer<UInt16>,
        _ key: UnsafeMutablePointer<UInt16>,
        _ flags: UnsafeMutablePointer<UInt32>
    ) -> Int32 {
        calls?.value(id, equivalent, key, flags) ?? -1
    }

    static func isEnabled(_ id: Int32) -> Bool { calls?.isEnabled(id) ?? false }
}
