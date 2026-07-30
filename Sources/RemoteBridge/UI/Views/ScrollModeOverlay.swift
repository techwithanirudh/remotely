import AppKit
import SwiftUI

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

        let chip = NSPanel(
            contentRect: NSRect(origin: .zero, size: Chip.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        chip.isOpaque = false
        chip.backgroundColor = .clear
        chip.hasShadow = false
        chip.level = .statusBar
        chip.ignoresMouseEvents = true
        chip.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let host = NSHostingController(rootView: Chip())
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        chip.contentViewController = host
        chip.setContentSize(Chip.panelSize)
        chip.orderFrontRegardless()
        panel = chip

        reposition()
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

    private func reposition() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation
        let size = panel.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? .zero
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
