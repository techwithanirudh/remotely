import AppKit
import CoreGraphics

@MainActor
enum NavigationTarget {
    private static var lastOther = ""
    private static var observer: (any NSObjectProtocol)?

    static var bundleID: String {
        start()
        if let pointed = appUnderPointer(), pointed != ownBundleID { return pointed }

        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        if frontmost != ownBundleID { return frontmost }
        return lastOther
    }

    static func start() {
        guard observer == nil else { return }
        remember(NSWorkspace.shared.frontmostApplication)
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            let key = NSWorkspace.applicationUserInfoKey
            let app = notification.userInfo?[key] as? NSRunningApplication
            MainActor.assumeIsolated { remember(app) }
        }
    }

    static func activateIfNeeded(_ bundleID: String) -> Bool {
        guard !bundleID.isEmpty,
              NSWorkspace.shared.frontmostApplication?.bundleIdentifier != bundleID,
              let app = NSRunningApplication.runningApplications(
                  withBundleIdentifier: bundleID
              ).first
        else { return false }
        return app.activate()
    }

    private static func appUnderPointer() -> String? {
        let pointer = CGEvent(source: nil)?.location ?? .zero
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
            as? [[CFString: Any]]
        else { return nil }

        for window in windows {
            guard (window[kCGWindowLayer] as? Int) == 0,
                  let bounds = window[kCGWindowBounds] as? [CFString: Any],
                  let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary),
                  rect.contains(pointer),
                  let pid = window[kCGWindowOwnerPID] as? pid_t,
                  let app = NSRunningApplication(processIdentifier: pid),
                  let id = app.bundleIdentifier
            else { continue }
            return id
        }
        return nil
    }

    private static var ownBundleID: String { Bundle.main.bundleIdentifier ?? "" }

    private static func remember(_ app: NSRunningApplication?) {
        guard let id = app?.bundleIdentifier, id != ownBundleID
        else { return }
        lastOther = id
    }
}
