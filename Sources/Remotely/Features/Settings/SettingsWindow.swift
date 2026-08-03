import AppKit
import ComposableArchitecture
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    /// The caller decides when closing should return the app to accessory mode.
    var onClose: (() -> Void)?

    init(settings: StoreOf<SettingsFeature>, remote: StoreOf<RemoteFeature>) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 685, height: 687),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Remotely"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        // Automatic draws its rule across the sidebar instead of only the page.
        window.titlebarSeparatorStyle = .none
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        // Restoration overrides centering and drifts the window on each launch.
        window.isRestorable = false
        window.minSize = NSSize(width: 660, height: 600)
        window.contentViewController = NSHostingController(
            rootView: SettingsView(store: settings, remote: remote)
        )
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        // The transparent content layer carries the measured corner shape.
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = Theme.Window.radius
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true

        super.init(window: window)
        window.delegate = self
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    func show() {
        if window?.isVisible != true { center() }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        alignWindowButtons()
    }

    func windowDidResize(_ notification: Notification) { alignWindowButtons() }
    func windowDidBecomeKey(_ notification: Notification) { alignWindowButtons() }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    /// The hosting controller sizes late, so centering needs layout first.
    private func center() {
        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        window.layoutIfNeeded()

        let visible = screen.visibleFrame
        var size = window.frame.size
        if size.width < window.minSize.width || size.height < window.minSize.height {
            size = NSSize(width: 685, height: 687)
            window.setContentSize(size)
        }
        window.setFrameOrigin(
            NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        )
    }

    /// Window buttons sit on the sidebar icon rail.
    private func alignWindowButtons() {
        guard let window else { return }
        let buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
            .compactMap { window.standardWindowButton($0) }

        for (index, button) in buttons.enumerated() {
            guard let titlebar = button.superview else { continue }
            let centerY = titlebar.bounds.height - Theme.Sidebar.lightTop
            button.setFrameOrigin(
                NSPoint(
                    x: Theme.Sidebar.lightInset + CGFloat(index) * Theme.Sidebar.lightGap,
                    y: centerY - button.bounds.height / 2
                )
            )
        }
    }
}
