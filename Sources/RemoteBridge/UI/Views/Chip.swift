import RemoteKit
import SwiftUI

struct Chip: View {
    /// Shadow room inside the borderless panel.
    static let margin: CGFloat = 9
    static let size = CGSize(width: 92, height: 22)
    static var panelSize: NSSize {
        NSSize(width: size.width + margin * 2, height: size.height + margin * 2)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: RemoteAction.toggleScrolling.symbol)
                .font(.system(size: 9.5, weight: .semibold))
            Text("Scrolling").font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color.purple.gradient, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.26), radius: 4, y: 1.5)
        .padding(Self.margin)
    }
}
