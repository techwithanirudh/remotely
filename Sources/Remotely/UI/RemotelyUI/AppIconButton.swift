import AppKit
import SwiftUI

struct AppIconButton: View {
    let size: CGFloat

    /// `Click.wav` is 80ms: a 200Hz to 700Hz sine sweep with FM, rendered from
    /// the "click" recipe in the `core` pack of @web-kits/audio by Raphael
    /// Salaja, MIT. Every system sound is a bell whose length is mostly
    /// ring-out, so none of them worked.
    ///
    /// One instance for the whole app. A fresh `NSSound` per click layers them
    /// on top of each other, and `play()` after `stop()` resumes from where it
    /// stopped unless the time is reset.
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
        // A no-op on a Mac without a Force Touch trackpad, which is most of
        // them, so it accompanies the sound rather than replacing it.
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)

        guard let click = Self.click else { return }
        click.stop()
        click.currentTime = 0
        click.play()
    }
}
