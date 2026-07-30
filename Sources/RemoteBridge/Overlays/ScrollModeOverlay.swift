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
        if visible {
            show()
        } else {
            hide()
        }
    }

    private func show() {
        guard panel == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Chip.panelSize),
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
        panel.setContentSize(Chip.panelSize)
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

    /// Tucked in under the cursor's tip, flipping when it would run off screen.
    ///
    /// The panel is larger than the chip so the shadow has somewhere to fall,
    /// so the placement works from the chip's own edges rather than the frame's.
    private func reposition() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation
        let size = panel.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? .zero
        // Close enough to read as attached to the pointer, clear enough not to
        // sit under the arrow itself, which is about 20pt tall.
        let gap: CGFloat = 10

        var origin = NSPoint(
            x: mouse.x + gap - Chip.margin,
            y: mouse.y - gap - size.height + Chip.margin
        )
        if mouse.x + gap + Chip.size.width > bounds.maxX {
            origin.x = mouse.x - gap - Chip.size.width - Chip.margin
        }
        if mouse.y - gap - Chip.size.height < bounds.minY {
            origin.y = mouse.y + gap - Chip.margin
        }
        panel.setFrameOrigin(origin)
    }
}

private struct Chip: View {
    /// Room inside the panel for the shadow to fall. A borderless panel clips
    /// to its own bounds, and a chip sized to the frame had its shadow sliced
    /// off square along the bottom.
    static let margin: CGFloat = 9
    static let size = CGSize(width: 92, height: 22)
    static var panelSize: NSSize {
        NSSize(width: size.width + margin * 2, height: size.height + margin * 2)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.up.and.down.text.horizontal")
                .font(.system(size: 9.5, weight: .semibold))
            Text("Scrolling").font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color.purple.gradient, in: Capsule())
        // A hairline of the tint's own light along the top, which is what keeps
        // the capsule from reading as a flat sticker over bright wallpaper.
        .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.26), radius: 4, y: 1.5)
        .padding(Self.margin)
    }
}
