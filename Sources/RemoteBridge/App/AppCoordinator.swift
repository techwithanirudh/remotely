import AppKit
import Combine
import Defaults
import LaunchAtLogin
import RemoteKit

@MainActor
final class AppCoordinator: NSObject, NSApplicationDelegate {
    private(set) static var shared: AppCoordinator?

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

        showFirstWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        bridge.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showFirstWindow()
        return true
    }

    func showFirstWindow() {
        if Defaults[.onboardingDone] {
            showSettings()
        } else {
            showOnboarding()
        }
    }

    func replayOnboarding() {
        Defaults[.onboardingDone] = false
        Defaults[.onboardingStep] = 0
        showOnboarding()
    }

    func factoryReset() {
        LaunchAtLogin.isEnabled = false
        bridge.resetPreferences()
        onboarding?.close()
        onboarding = nil
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
            isEnabled: bridge.isEnabled
        )
    }

    func showSettings() {
        if settings == nil {
            let controller = SettingsWindowController(bridge: bridge)
            controller.onClose = { [weak self] in
                // The guide may have just replaced it, and going accessory
                // would hide that too.
                guard self?.onboarding?.window?.isVisible != true else { return }
                NSApp.setActivationPolicy(.accessory)
            }
            settings = controller
        }
        // A menu bar app is .accessory, which cannot take proper key focus.
        NSApp.setActivationPolicy(.regular)
        settings?.show()
        bridge.refreshPermission()
    }

    /// Reuses the open guide. Building a second one left two panels on screen,
    /// each on its own step.
    func showOnboarding() {
        if onboarding == nil {
            onboarding = OnboardingWindowController(bridge: bridge) { [weak self] in
                Defaults[.onboardingDone] = true
                self?.onboarding?.close()
                self?.onboarding = nil
                self?.showSettings()
            }
        }
        NSApp.setActivationPolicy(.regular)
        onboarding?.show()
        settings?.close()
    }

    func copyLog() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bridge.logText(), forType: .string)
    }
}
