import AppKit

@MainActor
package enum NavigationTarget {
    private static var lastOther = ""
    private static var observer: (any NSObjectProtocol)?

    static var bundleID: String {
        start()
        return resolve(
            frontmost: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            own: ownBundleID,
            lastOther: lastOther
        )
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

    static func isFrontmost(_ id: String) -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id
    }

    static func focus(_ id: String) async -> Bool {
        guard !id.isEmpty else { return false }
        if isFrontmost(id) { return true }
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: id
        ).first, app.activate() else {
            return false
        }

        let deadline = ContinuousClock.now + .milliseconds(500)
        while !isFrontmost(id), ContinuousClock.now < deadline {
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                return false
            }
        }
        return isFrontmost(id)
    }

    package nonisolated static func resolve(
        frontmost: String?,
        own: String,
        lastOther: String
    ) -> String {
        guard let frontmost, !frontmost.isEmpty, frontmost != own else {
            return lastOther
        }
        return frontmost
    }

    private static var ownBundleID: String { Bundle.main.bundleIdentifier ?? "" }

    private static func remember(_ app: NSRunningApplication?) {
        guard let id = app?.bundleIdentifier, id != ownBundleID
        else { return }
        lastOther = id
    }
}
