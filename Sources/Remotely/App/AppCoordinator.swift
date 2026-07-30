import AppKit
import Combine
import Defaults
import LaunchAtLogin
import RemotelyKit

@MainActor
final class AppCoordinator: NSObject, NSApplicationDelegate {
    private(set) static var shared: AppCoordinator?

    private let remote = Remote()
    private let overlay = ScrollModeOverlay()
    private var statusItem: StatusItemController?
    private var settings: SettingsWindowController?
    private var onboarding: OnboardingWindowController?
    private var observers = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self

        _ = Updater.shared
        statusItem = StatusItemController(
            onToggle: { [weak self] in self?.remote.isEnabled.toggle() },
            onSettings: { [weak self] in self?.showSettings() },
            onCopyLog: { [weak self] in self?.copyLog() },
            onCheckForUpdates: { Updater.shared.checkForUpdates() },
            onQuit: { NSApp.terminate(nil) }
        )

        remote.onScrollingChange = { [weak self] isScrolling in
            self?.overlay.setVisible(isScrolling)
        }
        observe()
        remote.start()

        showFirstWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        remote.stop()
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

    func checkForUpdates() {
        Updater.shared.checkForUpdates()
    }

    func replayOnboarding() {
        Defaults[.onboardingDone] = false
        Defaults[.onboardingStep] = 0
        showOnboarding()
    }

    func factoryReset() {
        LaunchAtLogin.isEnabled = false
        remote.resetPreferences()
        onboarding?.close()
        onboarding = nil
        showOnboarding()
    }
}

private extension AppCoordinator {
    func observe() {
        remote.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.refreshStatusItem() }
            .store(in: &observers)

        // Accessibility can be granted while the app runs and macOS sends no
        // notification when it is.
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.remote.refreshPermission() }
        }
        RunLoop.main.add(timer, forMode: .common)

        refreshStatusItem()
    }

    func refreshStatusItem() {
        statusItem?.update(
            status: remote.status,
            isEnabled: remote.isEnabled
        )
    }

    func showSettings() {
        if settings == nil {
            let controller = SettingsWindowController(remote: remote)
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
        remote.refreshPermission()
    }

    /// Reuses the open guide. Building a second one left two panels on screen,
    /// each on its own step.
    func showOnboarding() {
        if onboarding == nil {
            onboarding = OnboardingWindowController(remote: remote) { [weak self] in
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
        NSPasteboard.general.setString(remote.logText(), forType: .string)
    }
}
