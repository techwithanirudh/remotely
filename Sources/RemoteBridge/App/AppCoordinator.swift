import AppKit
import Combine
import Defaults
import RemoteKit

/// Owns the app's windows and wires them to the bridge.
@MainActor
final class AppCoordinator: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppCoordinator?

    private let bridge = RemoteBridge()
    private let overlay = ScrollModeOverlay()
    private var statusItem: StatusItemController?
    private var settings: SettingsWindowController?
    private var onboarding: OnboardingWindowController?
    private var observers = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self

        statusItem = StatusItemController(
            onToggle: { [weak self] in self?.bridge.isEnabled.toggle() },
            onSettings: { [weak self] in self?.showSettings() },
            onCopyLog: { [weak self] in self?.copyLog() },
            onQuit: { NSApp.terminate(nil) }
        )

        bridge.onScrollingChange = { [weak self] isScrolling in
            self?.overlay.setVisible(isScrolling)
        }
        observe()
        bridge.start()

        restartOnboardingIfReinstalled()
        Defaults[.onboardingDone] ? showSettings() : showOnboarding()
    }

    func applicationWillTerminate(_ notification: Notification) {
        bridge.stop()
    }

    /// A menu bar app has no Dock icon to bounce, so opening it again should
    /// bring Settings forward rather than doing nothing.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings()
        return true
    }

    func replayOnboarding() {
        Defaults[.onboardingDone] = false
        Defaults[.onboardingStep] = 0
        settings?.close()
        showOnboarding()
    }
}

private extension AppCoordinator {
    func observe() {
        bridge.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.refreshStatusItem() }
            .store(in: &observers)

        // Accessibility can be granted while the app runs and macOS sends no
        // notification when it is.
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.bridge.refreshPermission() }
        }
        RunLoop.main.add(timer, forMode: .common)

        refreshStatusItem()
    }

    func refreshStatusItem() {
        statusItem?.update(
            status: bridge.status,
            lastKey: bridge.lastKey,
            isEnabled: bridge.isEnabled
        )
    }

    func showSettings() {
        if settings == nil {
            settings = SettingsWindowController(bridge: bridge)
        }
        // A menu bar app is .accessory, which cannot take proper key focus.
        NSApp.setActivationPolicy(.regular)
        settings?.show()
        bridge.refreshPermission()
    }

    func showOnboarding() {
        let controller = OnboardingWindowController(bridge: bridge) { [weak self] in
            Defaults[.onboardingDone] = true
            self?.onboarding?.close()
            self?.onboarding = nil
            self?.showSettings()
        }
        onboarding = controller
        NSApp.setActivationPolicy(.regular)
        controller.show()
    }

    func copyLog() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bridge.logText(), forType: .string)
    }

    /// Replacing the bundle revokes Accessibility, because the ad-hoc signature
    /// changes with every build, so setup genuinely has to be redone.
    func restartOnboardingIfReinstalled() {
        guard let path = Bundle.main.executablePath,
              let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let modified = attributes[.modificationDate] as? Date
        else { return }

        let build = String(Int(modified.timeIntervalSince1970))
        guard Defaults[.installedBuild] != build else { return }

        Defaults[.installedBuild] = build
        Defaults[.onboardingDone] = false
        Defaults[.onboardingStep] = 0
    }
}
