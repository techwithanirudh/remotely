import AppKit
import RemoteKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController {
    init(bridge: RemoteBridge, onFinish: @escaping () -> Void) {
        let window = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: Theme.Onboarding.size),
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
        window.setContentSize(Theme.Onboarding.size)

        super.init(window: window)
    }

    @available(*, unavailable)
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

private final class KeyablePanel: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
