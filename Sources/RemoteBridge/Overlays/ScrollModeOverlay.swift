import AppKit
import SwiftUI

/// A chip that follows the pointer while scroll mode is on.
///
/// Scroll mode changes what every arrow does, and nothing else on screen says
/// which mode you are in: the same press either moves the pointer or scrolls,
/// with no way to tell until you try it.
@MainActor
final class ScrollModeOverlay {
    private var panel: NSPanel?
    private var follower: Timer?

    func setVisible(_ visible: Bool) {
        visible ? show() : hide()
    }

    private func show() {
        guard panel == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 116, height: 34),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // The panel draws no shape of its own; its rounded backing showed
        // through behind the capsule and read as a second, squarer edge.
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let host = NSHostingController(rootView: Chip())
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = host
        panel.setContentSize(NSSize(width: 116, height: 34))
        panel.orderFrontRegardless()
        self.panel = panel

        reposition()
        // Common modes, so the chip keeps up while a menu is tracking.
        let timer = Timer(timeInterval: 1 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reposition() }
        }
        RunLoop.main.add(timer, forMode: .common)
        follower = timer
    }

    private func hide() {
        follower?.invalidate()
        follower = nil
        panel?.orderOut(nil)
        panel = nil
    }

    /// Sits below-right of the cursor, flipping when it would run off screen.
    private func reposition() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation
        let size = panel.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? .zero

        var origin = NSPoint(x: mouse.x + 18, y: mouse.y - size.height - 12)
        if origin.x + size.width > bounds.maxX { origin.x = mouse.x - size.width - 18 }
        if origin.y < bounds.minY { origin.y = mouse.y + 18 }
        panel.setFrameOrigin(origin)
    }
}

private struct Chip: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up.and.down.text.horizontal")
                .font(.system(size: 11, weight: .semibold))
            Text("Scrolling").font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(Color.purple, in: Capsule())
        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
