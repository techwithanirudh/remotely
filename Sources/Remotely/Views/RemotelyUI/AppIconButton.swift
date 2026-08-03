import AppKit
import SwiftUI

struct AppIconButton: View {
    let size: CGFloat

    /// Rendered from the `core` pack of @web-kits/audio by Raphael Salaja, MIT.
    /// One instance, because a fresh `NSSound` per click layers them.
    @MainActor private static let click: NSSound? = {
        guard let url = Bundle.main.url(forResource: "Click", withExtension: "wav") else {
            return nil
        }
        return NSSound(contentsOf: url, byReference: true)
    }()

    var body: some View {
        Button(action: play) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: size, height: size)
        }
        .buttonStyle(.pressScale)
        .focusable(false)
        .accessibilityHidden(true)
    }

    private func play() {
        // A no-op without a Force Touch trackpad.
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)

        guard let click = Self.click else { return }
        click.stop()
        click.currentTime = 0
        click.play()
    }
}
