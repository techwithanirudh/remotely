import SwiftUI

/// Surface styling and layout metrics.
///
/// The spacing values are measured from Alcove's window rather than guessed;
/// matching it by eye is what kept the window buttons looking misaligned.
enum Theme {
    /// Sidebar rows and the status pill: about a third of the 38pt row.
    static let cornerRadius: CGFloat = 13
    static let cardRadius: CGFloat = 12
    static let panelRadius: CGFloat = 22
    /// Measured off Alcove's corner: about 26pt, well past AppKit's default.
    static let windowRadius: CGFloat = 26

    // MARK: Layout

    static let sidebarWidth: CGFloat = 223
    /// Left edge of a sidebar row's background.
    static let sidebarInset: CGFloat = 11
    /// Padding inside a row, which puts its icon on the window-button rail.
    static let rowPadding: CGFloat = 8
    /// Distance from a leading icon to the label beside it.
    static let iconGap: CGFloat = 8
    /// Alcove's sidebar rows measure 38pt, not the 34 this used to assume.
    static let rowHeight: CGFloat = 38
    static let pageInset: CGFloat = 18
    static let cardPadding: CGFloat = 13
    /// A single-line row inside a card.
    static let rowHeightCompact: CGFloat = 42
    /// Width reserved for a bare glyph leading a row, so labels line up whether
    /// the row leads with a glyph or a filled tile.
    static let glyphColumn: CGFloat = 20

    /// Window buttons sit level with the sidebar row icons, 22pt down.
    static let trafficLightInset: CGFloat = sidebarInset + rowPadding
    static let trafficLightSpacing: CGFloat = 23
    static let trafficLightTop: CGFloat = 22

    // MARK: Colour

    /// Alcove's cards lift the window's own tint by about 5%, not the 10% ours
    /// were using. What separates a card there is its edge, not a brighter
    /// fill, and matching the fill without matching the edge is what made ours
    /// read as slabs of white laid on the material.
    static var cardFill: Color {
        adaptive(light: .init(white: 1, alpha: 0.52), dark: .init(white: 1, alpha: 0.055))
    }

    /// Sampled from Alcove: its card edge reads 197 where the fill reads 245,
    /// which is black at about 16%. Ours matched the divider instead, so the
    /// cards had no more outline than the rules inside them.
    static var cardStroke: Color {
        adaptive(light: .init(white: 0, alpha: 0.16), dark: .init(white: 1, alpha: 0.10))
    }

    /// Alcove's cards darken the ground by about 2% for a pixel and a half
    /// outside the edge, so the shadow is tight rather than soft.
    static var cardShadow: Color {
        adaptive(light: .init(white: 0, alpha: 0.05), dark: .init(white: 0, alpha: 0.18))
    }

    /// The lit top edge Alcove's window carries. It measures 55% white on the
    /// topmost pixel and is gone entirely by 50pt down, so it is a top edge
    /// rather than a ring.
    static var windowHighlight: Color {
        adaptive(light: .init(white: 1, alpha: 0.6), dark: .init(white: 1, alpha: 0.14))
    }

    /// How far the sidebar and page title fade once the window is not in front.
    static let inactiveDim: Double = 0.6

    /// A tint laid behind its own icon or label. Eight surfaces were painting
    /// this by hand at six different alphas.
    static let tintWash: Double = 0.13
    static let tintWashSoft: Double = 0.09

    /// The one duration anything in the window changes state over.
    static let stateChange: Animation = .easeOut(duration: 0.18)

    static var divider: Color { .primary.opacity(0.10) }
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
            .shadow(color: Theme.cardShadow, radius: 2, y: 1)
    }
}

/// The hairline that lights the top of the window and fades out as it turns the
/// corner. Drawn inside the window's own radius so the two curves agree.
struct WindowEdgeHighlight: View {
    var radius: CGFloat = Theme.windowRadius

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [Theme.windowHighlight, .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.07)
                ),
                lineWidth: 0.5
            )
            .allowsHitTesting(false)
    }
}
