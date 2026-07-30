import AppKit

/// Whether an external display is attached.
///
/// `CECLink` cannot answer this. It only learns a display exists from a log line
/// carrying an EDID, and `corercd` writes those when there is bus traffic, which
/// a button press creates. So on every launch the status told the user to check
/// their cable, with a working display plugged in.
@MainActor
public enum AttachedDisplay {
    public static var isAttached: Bool {
        NSScreen.screens.contains { !isBuiltIn($0) }
    }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let id = screen.deviceDescription[key] as? NSNumber else { return false }
        return CGDisplayIsBuiltin(CGDirectDisplayID(id.uint32Value)) != 0
    }
}
