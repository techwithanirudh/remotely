import AppKit
import Combine
import SwiftUI
import RemoteCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = BridgeModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menuHeader = MenuHeaderView()
    private let headerItem = NSMenuItem()
    private let lastButtonItem = NSMenuItem(title: "Last button: None", action: nil, keyEquivalent: "")
    private let enabledItem = NSMenuItem(title: "Enable", action: #selector(toggleEnabled), keyEquivalent: "")
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        observeModel()
        model.start()

        if OnboardingProgress.isComplete {
            showSettings()
        } else {
            showOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stop()
    }

    /// Opening the app again while it is already running has no Dock icon to
    /// bounce, so bring Settings forward instead of doing nothing.
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows: Bool
    ) -> Bool {
        showSettings()
        return true
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "av.remote.fill",
            accessibilityDescription: "Remote Bridge"
        )
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.toolTip = "Remote Bridge"

        let menu = NSMenu()
        menu.minimumWidth = 272
        headerItem.view = menuHeader
        menu.addItem(headerItem)

        lastButtonItem.isEnabled = false
        lastButtonItem.image = menuImage("button.programmable")
        menu.addItem(lastButtonItem)
        menu.addItem(.separator())

        enabledItem.target = self
        enabledItem.image = menuImage("power")
        menu.addItem(enabledItem)

        let settings = NSMenuItem(
            title: "Settings…",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settings.keyEquivalentModifierMask = .command
        settings.target = self
        settings.image = menuImage("gearshape")
        menu.addItem(settings)

        menu.addItem(.separator())

        let copy = NSMenuItem(
            title: "Copy Diagnostic Log",
            action: #selector(copyLog),
            keyEquivalent: ""
        )
        copy.target = self
        copy.image = menuImage("doc.on.doc")
        menu.addItem(copy)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        quit.image = menuImage("xmark.circle")
        menu.addItem(quit)

        statusItem.menu = menu
        refreshMenu()
    }

    private func observeModel() {
        model.$connectionState
            .sink { [weak self] _ in self?.refreshMenu() }
            .store(in: &cancellables)

        model.$lastCommand
            .sink { [weak self] _ in self?.refreshMenu() }
            .store(in: &cancellables)

        model.$bridgeEnabled
            .sink { [weak self] _ in self?.refreshMenu() }
            .store(in: &cancellables)

        model.$accessibilityGranted
            .sink { [weak self] _ in self?.refreshMenu() }
            .store(in: &cancellables)

        // Accessibility can be granted while the app runs, and macOS sends no
        // notification when it is.
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.refreshPermissions() }
        }
    }

    private func refreshMenu() {
        menuHeader.update(status: model.status)
        statusItem.button?.toolTip = "Remote Bridge: \(model.status.title)"

        lastButtonItem.title = "Last button: \(model.lastCommand?.displayName ?? "None")"
        enabledItem.state = model.bridgeEnabled ? .on : .off
    }

    private func menuImage(_ symbol: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.size = NSSize(width: 15, height: 15)
        return image
    }

    @objc private func toggleEnabled() {
        model.bridgeEnabled.toggle()
    }

    @objc private func copyLog() {
        model.copyLogs()
    }

    static let onboardingKey = OnboardingProgress.completedKey

    @objc func replayOnboarding() {
        OnboardingProgress.replay()
        settingsWindowController?.close()
        showOnboarding()
    }

    func showOnboarding() {
        let controller = OnboardingWindowController(model: model) { [weak self] in
            OnboardingProgress.markComplete()
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
            self?.showSettings()
        }
        onboardingWindowController = controller
        NSApplication.shared.setActivationPolicy(.regular)
        controller.show()
    }

    @objc func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(model: model)
        }
        // A menu bar app is .accessory, which cannot take proper key focus.
        // Become a regular app while the window is up; closing it reverts.
        NSApplication.shared.setActivationPolicy(.regular)
        settingsWindowController?.show()
        model.refreshPermissions()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

@MainActor
private final class MenuHeaderView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Remote Bridge")
    private let statusLabel = NSTextField(labelWithString: "Starting…")
    private let dotView = NSView()

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 272, height: 59))

        iconView.image = NSImage(
            systemSymbolName: "av.remote.fill",
            accessibilityDescription: "Remote Bridge"
        )
        iconView.symbolConfiguration = .init(pointSize: 19, weight: .medium)
        iconView.contentTintColor = .labelColor

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        dotView.wantsLayer = true
        dotView.layer?.cornerRadius = 3

        [iconView, titleLabel, statusLabel, dotView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 272),
            heightAnchor.constraint(equalToConstant: 59),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            dotView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dotView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 6),
            statusLabel.centerYAnchor.constraint(equalTo: dotView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(status: BridgeStatus) {
        statusLabel.stringValue = status.title
        dotView.layer?.backgroundColor = color(for: status).cgColor
    }

    private func color(for status: BridgeStatus) -> NSColor {
        switch status {
        case .ready: .systemGreen
        case .waitingForRemote, .needsPermission: .systemOrange
        case .unsupported, .failed: .systemRed
        case .paused: .secondaryLabelColor
        }
    }
}

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    init(model: BridgeModel) {
        let rootView = SettingsRootView(model: model)
        let hostingController = NSHostingController(rootView: rootView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Remote Bridge"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 700, height: 590)
        window.setFrameAutosaveName("RemoteBridgeSettings")
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alignTrafficLights()
    }

    func windowDidResize(_ notification: Notification) {
        alignTrafficLights()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        alignTrafficLights()
    }

    /// Lines the window buttons up with the sidebar row icons. AppKit parks them
    /// 7pt from the edge, which reads as misaligned against everything below.
    /// Only x moves — nudging y is what makes them look wrong.
    private func alignTrafficLights() {
        guard let window else { return }
        let buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
            .compactMap { window.standardWindowButton($0) }

        for (index, button) in buttons.enumerated() {
            guard let titlebar = button.superview else { continue }
            // AppKit's y origin is bottom-left, so measure down from the top of
            // the titlebar view.
            let centreY = titlebar.bounds.height - Theme.trafficLightTopInset
            button.setFrameOrigin(
                NSPoint(
                    x: Theme.trafficLightInset + CGFloat(index) * Theme.trafficLightSpacing,
                    y: centreY - button.bounds.height / 2
                )
            )
        }
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@MainActor
final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    init(model: BridgeModel, onFinish: @escaping () -> Void) {
        let rootView = OnboardingView(model: model, onFinish: onFinish)

        // Borderless, the way Alcove's onboarding is: no titlebar and no window
        // buttons, so nothing in the panel has to line up with them.
        let window = KeyableBorderlessWindow(
            contentRect: NSRect(origin: .zero, size: OnboardingView.panelSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.contentViewController = NSHostingController(rootView: rootView)
        window.setContentSize(OnboardingView.panelSize)

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Position against the screen once the window is up; `center()` uses
        // whatever size it has at call time, which is stale until layout runs.
        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(
            NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        )
    }

    // Closing mid-flow deliberately does not mark onboarding complete: quitting
    // to grant Accessibility is a normal part of getting set up, and treating
    // that as "finished" was what stopped the flow resuming. Only reaching the
    // end completes it.
}

/// A borderless window still has to accept keyboard focus for its buttons.
final class KeyableBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

