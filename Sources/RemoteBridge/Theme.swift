import SwiftUI

/// Shared surface styling and layout metrics.
///
/// Colours resolve through semantic system colours so the window reads correctly
/// in both appearances. Hardcoded white/black opacities were what washed out
/// light mode, and materials layered over a translucent window were what made
/// cards look broken where content scrolled beneath them.
///
/// The spacing values are measured from Alcove's own window rather than guessed,
/// since matching it by eye is what kept the traffic lights looking off.
enum Theme {
    static let cornerRadius: CGFloat = 10
    static let cardCornerRadius: CGFloat = 12

    /// Cards float on the window's vibrancy rather than sitting on an opaque
    /// pane. Alcove's read as near-white against the material behind them, so a
    /// faint wash is not enough: they have to be mostly opaque to separate.
    static var cardFill: Color {
        dynamic(light: .init(white: 1, alpha: 0.86), dark: .init(white: 1, alpha: 0.085))
    }

    /// Barely-there edge. Alcove separates cards with lift, not outline.
    static var cardStroke: Color {
        dynamic(light: .init(white: 0, alpha: 0.05), dark: .init(white: 1, alpha: 0.08))
    }

    /// Lifts the content side off the sidebar the way a real sidebar split does.
    static var contentWash: Color {
        dynamic(light: .init(white: 1, alpha: 0.34), dark: .init(white: 1, alpha: 0.02))
    }

    static var cardShadow: Color {
        dynamic(light: .init(white: 0, alpha: 0.05), dark: .init(white: 0, alpha: 0.18))
    }

    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
    static var divider: Color { Color.primary.opacity(0.07) }
    static var selectionFill: Color { Color.primary.opacity(0.08) }

    // MARK: Layout

    static let sidebarWidth: CGFloat = 223
    /// Left edge of a sidebar row's selection background.
    static let sidebarInset: CGFloat = 11
    /// Padding inside a sidebar row, putting its icon on the traffic-light rail.
    static let sidebarRowPadding: CGFloat = 8
    static let sidebarRowHeight: CGFloat = 34

    /// The window buttons sit level with the sidebar row icons
    /// (`sidebarInset` + `sidebarRowPadding`), not against the window edge.
    static let trafficLightInset: CGFloat = sidebarInset + sidebarRowPadding
    static let trafficLightSpacing: CGFloat = 23
    /// Distance from the window's top edge to the buttons' centre. AppKit's
    /// default sits them ~14.5pt down; Alcove's measure ~19.5pt, and leaving
    /// this alone is what kept the padding looking off.
    static let trafficLightTopInset: CGFloat = 22

    static let pageInset: CGFloat = 18
    static let cardPadding: CGFloat = 13
}

extension View {
    /// A floating card: near-opaque fill, hairline edge, one soft shadow.
    func cardSurface(cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        background(Theme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
            .shadow(color: Theme.cardShadow, radius: 3, y: 1)
    }
}
