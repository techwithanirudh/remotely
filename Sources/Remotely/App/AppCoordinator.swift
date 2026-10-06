import AppKit
import ComposableArchitecture

@MainActor
final class AppCoordinator: NSObject, NSApplicationDelegate {
    private let store: StoreOf<AppFeature>
    private let menuBar: MenuBarCoordinator
    private let windows: AppWindowCoordinator
    private let overlay: RemoteOverlayCoordinator

    override init() {
        let appStore = Store(initialState: AppFeature.State()) {
            AppFeature()
        }
        self.store = appStore
        menuBar = MenuBarCoordinator(store: appStore)
        windows = AppWindowCoordinator(store: appStore)
        overlay = RemoteOverlayCoordinator(store: appStore)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar.start()
        overlay.start()
        store.send(.didFinishLaunching(atLogin: launchedAtLogin))
        windows.start()
    }

    /// Only readable while the launch event is being handled, so it is passed
    /// along rather than asked for later.
    private var launchedAtLogin: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication
        else { return false }
        let launchKind = event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue
        return launchKind == keyAELaunchedAsLogInItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.send(.willTerminate)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        store.send(.reopen)
        return true
    }
}
