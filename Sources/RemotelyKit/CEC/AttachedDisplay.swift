import AppKit

/// Whether an external display is attached. `CECLink` cannot answer this: it
/// only learns of a display from an EDID line, which needs bus traffic.
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
