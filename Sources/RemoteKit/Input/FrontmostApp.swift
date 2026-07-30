import AppKit

/// The app a remote press is aimed at.
///
/// `NSWorkspace.frontmostApplication` is not that app while Settings has focus:
/// it is Remote Bridge, and Back then picks a navigation method for the wrong
/// target. Activations are watched instead, remembering the last one that was
/// somebody else.
@MainActor
public enum FrontmostApp {
    private static var lastOther = ""
    private static var observer: (any NSObjectProtocol)?

    public static var bundleID: String {
        start()
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        return front == ownBundleID ? lastOther : front
    }

    private static var ownBundleID: String { Bundle.main.bundleIdentifier ?? "" }

    private static func start() {
        guard observer == nil else { return }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { note in
            let key = NSWorkspace.applicationUserInfoKey
            let app = note.userInfo?[key] as? NSRunningApplication
            guard let id = app?.bundleIdentifier else { return }

            MainActor.assumeIsolated {
                guard id != ownBundleID else { return }
                lastOther = id
            }
        }
    }
}
