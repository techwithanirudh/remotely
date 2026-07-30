import AppKit
import SwiftUI

struct TargetProbe: NSViewRepresentable {
    @MainActor private weak static var current: Probe?

    @MainActor
    static func contains(_ point: NSPoint) -> Bool {
        current?.screenFrame.contains(point) ?? false
    }

    func makeNSView(context: Context) -> NSView { Probe() }
    func updateNSView(_ view: NSView, context: Context) {}

    private final class Probe: NSView {
        var screenFrame: NSRect {
            guard let window else { return .zero }
            return window.convertToScreen(convert(bounds, to: nil))
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            MainActor.assumeIsolated { TargetProbe.current = self }
        }
    }
}
