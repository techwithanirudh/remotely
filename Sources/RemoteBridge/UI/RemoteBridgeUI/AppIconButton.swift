import AppKit
import SwiftUI

struct AppIconButton: View {
    let size: CGFloat

    var body: some View {
        Button(action: playSound) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: size, height: size)
        }
        .buttonStyle(.pressScale)
        .focusable(false)
        .accessibilityHidden(true)
    }

    private func playSound() {
        NSSound(named: "Pop")?.play()
    }
}
