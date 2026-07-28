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
    private let enabledItem = NSMenuItem(title: "Enable Remote Bridge", action: #selector(toggleEnabled), keyEquivalent: "")
    private var settingsWindowController: SettingsWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        observeModel()
        model.start()

        if !UserDefaults.standard.bool(forKey: "hasOpenedPolishedSettings") {
            UserDefaults.standard.set(true, forKey: "hasOpenedPolishedSettings")
            showSettings()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stop()
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

        let reconnect = NSMenuItem(
            title: "Reconnect HDMI-CEC",
            action: #selector(reconnect),
            keyEquivalent: "r"
        )
        reconnect.target = self
        reconnect.image = menuImage("arrow.clockwise")
        menu.addItem(reconnect)

        menu.addItem(.separator())

        let test = NSMenuItem(
            title: "Test Pointer Movement",
            action: #selector(testMove),
            keyEquivalent: ""
        )
        test.target = self
        test.image = menuImage("cursorarrow.motionlines")
        menu.addItem(test)

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
            title: "Quit Remote Bridge",
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
    }

    private func refreshMenu() {
        menuHeader.update(state: model.connectionState)
        statusItem.button?.toolTip = "Remote Bridge — \(model.connectionState.displayName)"

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

    @objc private func reconnect() {
        model.reconnect()
    }

    @objc private func testMove() {
        model.test(.moveRight)
    }

    @objc private func copyLog() {
        model.copyLogs()
    }

    @objc func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(model: model)
        }
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

    func update(state: CECClient.State) {
        statusLabel.stringValue = state.displayName
        dotView.layer?.backgroundColor = color(for: state).cgColor
    }

    private func color(for state: CECClient.State) -> NSColor {
        switch state {
        case .running: .systemGreen
        case .waitingForHDMI: .systemOrange
        case .unsupported, .failed: .systemRed
        case .stopped: .secondaryLabelColor
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
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
