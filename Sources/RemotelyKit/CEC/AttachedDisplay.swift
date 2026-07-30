import AppKit

/// Whether an external display is attached, and what it is called.
///
/// `CECLink` cannot answer this. It only learns a display exists from a log line
/// carrying an EDID, and `corercd` writes those when there is bus traffic, which
/// a button press creates. So on every launch the status claimed no remote had
/// been seen and told the user to check their cable, with a working display
/// plugged in.
@MainActor
public enum AttachedDisplay {
    public static var name: String? {
        NSScreen.screens.lazy
            .filter { !isBuiltIn($0) }
            .map(\.localizedName)
            .first { !$0.isEmpty }
    }

    public static var isAttached: Bool { name != nil }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber else { return false }
        return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) != 0
    }
}
