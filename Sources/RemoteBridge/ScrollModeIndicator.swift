import AppKit
import SwiftUI

/// A small badge that follows the pointer while scroll mode is on.
///
/// Scroll mode changes what every arrow does, and nothing on screen said which
/// mode you were in: the same press either moved the pointer or scrolled, with
/// no way to tell which until you tried. This rides next to the cursor for as
/// long as the mode is active.
@MainActor
final class ScrollModeIndicator {
    private var window: NSWindow?
    private var follow: Timer?

    func setVisible(_ visible: Bool) {
        visible ? show() : hide()
    }

    private func show() {
        guard window == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 116, height: 30),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // The panel draws no shape of its own: its rounded backing showed
        // through behind the capsule and read as a second, squarer edge.
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let host = NSHostingController(rootView: ScrollModeChip())
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = host
        panel.setContentSize(NSSize(width: 116, height: 34))
        panel.orderFrontRegardless()
        window = panel

        reposition()
        // Common modes, so the chip keeps up with the pointer while a menu is
        // tracking rather than freezing where it was.
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reposition() }
        }
        RunLoop.main.add(timer, forMode: .common)
        follow = timer
    }

    private func hide() {
        follow?.invalidate()
        follow = nil
        window?.orderOut(nil)
        window = nil
    }

    /// Sits below-right of the cursor, flipping when it would run off screen.
    private func reposition() {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        let size = window.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? .zero

        var origin = NSPoint(x: mouse.x + 18, y: mouse.y - size.height - 12)
        if origin.x + size.width > bounds.maxX { origin.x = mouse.x - size.width - 18 }
        if origin.y < bounds.minY { origin.y = mouse.y + 18 }
        window.setFrameOrigin(origin)
    }
}

private struct ScrollModeChip: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up.and.down.text.horizontal")
                .font(.system(size: 11, weight: .semibold))

            Text("Scrolling")
                .font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 26)
        // One shape only. The stroke and the panel's own backing were each
        // adding an edge, so the capsule looked doubled.
        .background(Color.purple, in: Capsule())
        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
