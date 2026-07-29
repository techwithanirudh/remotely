import AppKit
import RemoteKit
import SwiftUI

/// Settings window.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private var isPlaced = false

    init(bridge: RemoteBridge) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Remote Bridge"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        // Automatic draws a rule under the titlebar once anything scrolls, which
        // landed as a bar across the whole window, sidebar included. The page
        // title carries that boundary itself.
        window.titlebarSeparatorStyle = .none
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 700, height: 590)
        window.contentViewController = NSHostingController(rootView: SettingsView(bridge: bridge))
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        // AppKit's own corner is squarer than Alcove's, and the window is
        // already transparent, so the content layer carries the shape.
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = Theme.windowRadius
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        centreOnce()
        alignWindowButtons()
    }

    func windowDidResize(_ notification: Notification) { alignWindowButtons() }
    func windowDidBecomeKey(_ notification: Notification) { alignWindowButtons() }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    /// Centres the first time it is shown. Doing it at init measures a frame
    /// the hosting controller has not sized yet, which parked it in a corner.
    private func centreOnce() {
        guard !isPlaced, let window, let screen = window.screen ?? NSScreen.main else { return }
        isPlaced = true

        let visible = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(
            NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        )
    }

    /// Lines the window buttons up with the sidebar icons. AppKit parks them
    /// 7pt in and 14.5pt down; Alcove's sit on the row rail, 22pt down.
    private func alignWindowButtons() {
        guard let window else { return }
        let buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
            .compactMap { window.standardWindowButton($0) }

        for (index, button) in buttons.enumerated() {
            guard let titlebar = button.superview else { continue }
            let centreY = titlebar.bounds.height - Theme.trafficLightTop
            button.setFrameOrigin(
                NSPoint(
                    x: Theme.trafficLightInset + CGFloat(index) * Theme.trafficLightSpacing,
                    y: centreY - button.bounds.height / 2
                )
            )
        }
    }
}

/// Onboarding panel: borderless, like Alcove's, so nothing has to line up with
/// window buttons that would serve no purpose here.
@MainActor
final class OnboardingWindowController: NSWindowController {
    init(bridge: RemoteBridge, onFinish: @escaping () -> Void) {
        let window = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: OnboardingView.panelSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        // Normal level: floating put the panel above the Accessibility prompt,
        // so the dialog the step is asking for opened behind it.
        window.level = .normal
        window.contentViewController = NSHostingController(
            rootView: OnboardingView(bridge: bridge, onFinish: onFinish)
        )
        window.setContentSize(OnboardingView.panelSize)

        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(
            NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        )
    }
}

/// A borderless window still has to accept focus for its buttons.
private final class KeyablePanel: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
