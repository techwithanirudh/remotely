import AppKit
import Combine
import ComposableArchitecture
import Defaults
import LaunchAtLogin
import RemotelyKit

@MainActor
final class AppCoordinator: NSObject, NSApplicationDelegate {
    private(set) static var shared: AppCoordinator?

    private let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    private let overlay = ScrollModeOverlay()
    private var statusItem: StatusItemController?
    private var settings: SettingsWindowController?
    private var onboarding: OnboardingWindowController?
    private var observers = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        RemoteClientLive.bootstrap()

        _ = Updater.shared
        statusItem = StatusItemController(
            onToggle: { [weak self] in
                guard let self else { return }
                self.store.send(.remote(.setEnabled(!self.store.remote.isEnabled)))
            },
            onSettings: { [weak self] in self?.showSettings() },
            onCopyLog: { [weak self] in self?.copyLog() },
            onCheckForUpdates: { [weak self] in
                self?.store.send(.settings(.checkForUpdates))
            },
            onQuit: { NSApp.terminate(nil) }
        )

        statusItem?.isVisible = Defaults[.showsMenuBarIcon]
        Defaults.observe(.showsMenuBarIcon) { [weak self] change in
            self?.statusItem?.isVisible = change.newValue
        }.tieToLifetime(of: self)

        observe()
        store.send(.didFinishLaunching)

        showFirstWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.send(.remote(.stop))
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showFirstWindow()
        return true
    }

    func showFirstWindow() {
        if Defaults[.onboardingDone] {
            store.send(.showSettings)
            showSettings()
        } else {
            store.send(.showOnboarding)
            showOnboarding()
        }
    }

    func checkForUpdates() {
        store.send(.settings(.checkForUpdates))
    }

    func replayOnboarding() {
        Defaults[.onboardingDone] = false
        Defaults[.onboardingStep] = 0
        store.send(.settings(.delegate(.replayOnboarding)))
    }

    func factoryReset() {
        LaunchAtLogin.isEnabled = false
        store.send(.settings(.delegate(.factoryReset)))
        onboarding?.close()
        onboarding = nil
    }
}

private extension AppCoordinator {
    func observe() {
        store.publisher.remote
            .receive(on: RunLoop.main)
            .sink { [weak self] remote in
                self?.overlay.setVisible(remote.isScrolling)
                self?.refreshStatusItem()
            }
            .store(in: &observers)

        store.publisher.window
            .removeDuplicates()
            .sink { [weak self] window in
                switch window {
                case .settings: self?.showSettings()
                case .onboarding: self?.showOnboarding()
                }
            }
            .store(in: &observers)

        // macOS sends no notification when Accessibility is granted.
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.store.send(.remote(.refreshPermission))
            }
        }
        RunLoop.main.add(timer, forMode: .common)

        refreshStatusItem()
    }

    func refreshStatusItem() {
        statusItem?.update(
            status: store.remote.status,
            isEnabled: store.remote.isEnabled
        )
    }

    func showSettings() {
        if settings == nil {
            let controller = SettingsWindowController(
                settings: store.scope(state: \.settings, action: \.settings),
                remote: store.scope(state: \.remote, action: \.remote)
            )
            controller.onClose = { [weak self] in
                // The guide may have just replaced it.
                guard self?.onboarding?.window?.isVisible != true else { return }
                NSApp.setActivationPolicy(.accessory)
            }
            settings = controller
        }
        // .accessory cannot take proper key focus.
        NSApp.setActivationPolicy(.regular)
        settings?.show()
        store.send(.remote(.refreshPermission))
    }

    /// Reuses the open guide; a second one left two panels on their own steps.
    func showOnboarding() {
        if onboarding == nil {
            onboarding = OnboardingWindowController(
                onboarding: store.scope(state: \.onboarding, action: \.onboarding),
                remote: store.scope(state: \.remote, action: \.remote)
            ) { [weak self] in
                self?.store.send(.showSettings)
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
        let text = store.remote.log
            .map { "\($0.time)  \($0.message)" }
            .joined(separator: "\n")
        NSPasteboard.general.setString(text, forType: .string)
    }
}
