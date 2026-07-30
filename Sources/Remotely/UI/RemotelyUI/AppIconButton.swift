import AppKit
import SwiftUI

struct AppIconButton: View {
    let size: CGFloat

    /// Tink is the shortest system sound at 0.56s, but most of that is a
    /// ring-out that reads as a chime, so only the attack is played. Pop is
    /// worse for this: 1.63s, nearly all tail.
    ///
    /// One instance for the whole app. A fresh `NSSound` per click layers them
    /// on top of each other, and `play()` after `stop()` resumes from where it
    /// stopped unless the time is reset.
    @MainActor private static let click = NSSound(named: "Tink")

    private static let attack = 0.09
    private static let level: Float = 0.4

    /// Counts clicks so a pending cutoff cannot silence a newer one.
    @MainActor private static var generation = 0

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
        Self.generation += 1
        let token = Self.generation

        click.stop()
        click.currentTime = 0
        click.volume = Self.level
        click.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.attack) {
            MainActor.assumeIsolated {
                guard token == Self.generation else { return }
                click.stop()
            }
        }
    }
}
