import SwiftUI

extension View {
    func card(radius: CGFloat = Theme.Card.radius) -> some View {
        background(Theme.Card.fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.Card.stroke, lineWidth: 1)
            }
            .shadow(color: Theme.Card.shadow, radius: 2, y: 1)
    }
}
