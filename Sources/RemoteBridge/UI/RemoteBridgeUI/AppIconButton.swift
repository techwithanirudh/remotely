import AppKit
import SwiftUI

struct AppIconButton: View {
    let size: CGFloat

    /// One instance for the whole app. A fresh `NSSound` per click layers them
    /// on top of each other, and `play()` after `stop()` resumes from where it
    /// stopped unless the time is reset.
    @MainActor private static let click = NSSound(named: "Bottle")

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
        guard let click = Self.click else { return }
        click.stop()
        click.currentTime = 0
        click.play()
    }
}
