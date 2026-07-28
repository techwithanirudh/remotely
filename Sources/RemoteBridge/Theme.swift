import SwiftUI

/// Shared surface styling.
///
/// Everything here resolves through semantic system colours so the window reads
/// correctly in both appearances. Hardcoded white/black opacities were the cause
/// of the washed-out light mode, and layered materials over a translucent window
/// were what made cards look broken where content scrolled beneath them.
enum Theme {
    static let cornerRadius: CGFloat = 10
    static let cardCornerRadius: CGFloat = 12

    /// Opaque so scrolling content never shows through a card.
    static var cardFill: Color { Color(nsColor: .controlBackgroundColor) }
    static var cardStroke: Color { Color.primary.opacity(0.09) }
    static var divider: Color { Color.primary.opacity(0.07) }
    static var selectionFill: Color { Color.primary.opacity(0.08) }
    static var hoverFill: Color { Color.primary.opacity(0.04) }

    /// One left rail shared by the traffic lights, the status pill and the rows.
    static let sidebarInset: CGFloat = 14
    /// Same rail as the status pill and the card edges below it.
    static let trafficLightInset: CGFloat = sidebarInset
    static let trafficLightSpacing: CGFloat = 20
    static let sidebarWidth: CGFloat = 220
    static let pageInset: CGFloat = 22
}

extension View {
    /// A plain card: opaque fill, hairline border, no shadow.
    func cardSurface(cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        background(Theme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
    }
}
