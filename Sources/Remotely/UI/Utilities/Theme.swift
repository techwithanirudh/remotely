import SwiftUI

enum Theme {
    enum Control {
        static let radius: CGFloat = 13
    }

    enum Card {
        static let radius: CGFloat = 12
        static let inset: CGFloat = 13
        static let rowHeight: CGFloat = 42
        static let glyphWidth: CGFloat = 20

        static var fill: SwiftUI.Color {
            Theme.adaptive(light: .init(white: 1, alpha: 0.52), dark: .init(white: 1, alpha: 0.055))
        }

        static var stroke: SwiftUI.Color {
            Theme.adaptive(light: .init(white: 0, alpha: 0.16), dark: .init(white: 1, alpha: 0.10))
        }

        static var shadow: SwiftUI.Color {
            Theme.adaptive(light: .init(white: 0, alpha: 0.05), dark: .init(white: 0, alpha: 0.18))
        }
    }

    enum Panel {
        static let radius: CGFloat = 22
    }

    enum Sidebar {
        static let width: CGFloat = 223
        static let inset: CGFloat = 11
        static let rowInset: CGFloat = 8
        static let rowHeight: CGFloat = 38
        static let lightInset: CGFloat = inset + rowInset
        static let lightGap: CGFloat = 23
        static let lightTop: CGFloat = 22
    }

    enum Window {
        static let radius: CGFloat = 26

        static var highlight: SwiftUI.Color {
            Theme.adaptive(light: .init(white: 1, alpha: 0.6), dark: .init(white: 1, alpha: 0.14))
        }
    }

    enum Page {
        static let inset: CGFloat = 18
    }

    enum Onboarding {
        static let size = CGSize(width: 330, height: 505)
        static let insetX: CGFloat = 22
        static let insetY: CGFloat = 18
    }

    enum Space {
        static let icon: CGFloat = 8
        /// A row's glyph sits further from its label than a stacked one does.
        static let rowIcon: CGFloat = 11
    }

    enum Opacity {
        static let inactive = 0.6
        static let tint = 0.13
        static let tintSoft = 0.09
    }

    enum Motion {
        static let state = Animation.easeOut(duration: 0.18)
        static let pressScale = 0.97
        static let pressIn = Animation.easeOut(duration: 0.08)
        static let pressOut = Animation.spring(duration: 0.22, bounce: 0.18)
    }

    enum Color {
        static var divider: SwiftUI.Color { .primary.opacity(0.10) }
        static var selection: SwiftUI.Color { .primary.opacity(0.08) }
    }

    private static func adaptive(light: NSColor, dark: NSColor) -> SwiftUI.Color {
        SwiftUI.Color(nsColor: NSColor(name: nil) { mode in
            mode.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}
