import SwiftUI

struct WindowEdgeHighlight: View {
    var radius: CGFloat = Theme.Window.radius

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [Theme.Window.highlight, .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.07)
                ),
                lineWidth: 0.5
            )
            .allowsHitTesting(false)
    }
}
