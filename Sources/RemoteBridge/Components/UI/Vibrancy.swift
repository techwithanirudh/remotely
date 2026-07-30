import SwiftUI

/// Window vibrancy. The caller picks the material: `.underWindowBackground`
/// lets the desktop through, `.contentBackground` barely transmits, which is
/// what the window wants once it is no longer in front.
///
/// Held active, because following the window's state flattens the glass to the
/// window background rather than to a material.
struct Vibrancy: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}
