import SwiftUI

/// Surface styling and layout metrics.
///
/// The spacing values are measured from Alcove's window rather than guessed;
/// matching it by eye is what kept the window buttons looking misaligned.
enum Theme {
    static let cornerRadius: CGFloat = 10
    static let cardRadius: CGFloat = 12
    static let panelRadius: CGFloat = 22
    /// Alcove rounds its window further than AppKit does by default.
    static let windowRadius: CGFloat = 16

    // MARK: Layout

    static let sidebarWidth: CGFloat = 223
    /// Left edge of a sidebar row's background.
    static let sidebarInset: CGFloat = 11
    /// Padding inside a row, which puts its icon on the window-button rail.
    static let rowPadding: CGFloat = 8
    static let rowHeight: CGFloat = 34
    static let pageInset: CGFloat = 18
    static let cardPadding: CGFloat = 13

    /// Window buttons sit level with the sidebar row icons, 22pt down.
    static let trafficLightInset: CGFloat = sidebarInset + rowPadding
    static let trafficLightSpacing: CGFloat = 23
    static let trafficLightTop: CGFloat = 22

    // MARK: Colour

    /// Cards float on the window's vibrancy, so they have to be nearly opaque
    /// to separate from it. A faint wash disappeared against the material.
    static var cardFill: Color {
        adaptive(light: .init(white: 1, alpha: 0.86), dark: .init(white: 1, alpha: 0.085))
    }

    static var cardStroke: Color {
        adaptive(light: .init(white: 0, alpha: 0.05), dark: .init(white: 1, alpha: 0.10))
    }

    static var cardShadow: Color {
        adaptive(light: .init(white: 0, alpha: 0.05), dark: .init(white: 0, alpha: 0.18))
    }

    static var divider: Color { .primary.opacity(0.07) }
    static var selection: Color { .primary.opacity(0.08) }

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

extension View {
    /// A floating card: near-opaque fill, hairline edge, one soft shadow.
    func card(radius: CGFloat = Theme.cardRadius) -> some View {
        background(Theme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
            .shadow(color: Theme.cardShadow, radius: 3, y: 1)
    }
}
