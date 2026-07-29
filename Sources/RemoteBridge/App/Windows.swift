import AppKit
import RemoteKit
import SwiftUI

/// Settings window.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    /// Closing does not always mean the app is done showing windows, so who
    /// drops back to an accessory app is the caller's decision.
    var onClose: (() -> Void)?

    init(bridge: RemoteBridge) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 685, height: 687),
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
        // Restoration put the window back where it was last quit, which beat
        // the centring and drifted a little further each launch.
        window.isRestorable = false
        window.minSize = NSSize(width: 660, height: 600)
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
        // Cascading nudged the window down and right of center on every open.
        shouldCascadeWindows = false
    }

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

    /// Centered on each open, before it is shown so there is no jump.
    ///
    /// Layout is forced first: the hosting controller sizes the window late, and
    /// centring a frame still reading as empty put its corner on the middle of
    /// the screen rather than the window.
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

    /// Lines the window buttons up with the sidebar icons. AppKit parks them
    /// 7pt in and 14.5pt down; Alcove's sit on the row rail, 22pt down.
    private func alignWindowButtons() {
        guard let window else { return }
        let buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
            .compactMap { window.standardWindowButton($0) }

        for (index, button) in buttons.enumerated() {
            guard let titlebar = button.superview else { continue }
            let centerY = titlebar.bounds.height - Theme.trafficLightTop
            button.setFrameOrigin(
                NSPoint(
                    x: Theme.trafficLightInset + CGFloat(index) * Theme.trafficLightSpacing,
                    y: centerY - button.bounds.height / 2
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
