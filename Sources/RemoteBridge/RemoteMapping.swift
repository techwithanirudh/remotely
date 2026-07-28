import Foundation
import RemoteCore

/// A physical press or gesture the bridge can act on.
enum RemoteButton: String, CaseIterable, Identifiable {
    case up
    case down
    case left
    case right
    case center
    case centerDouble
    case centerHold
    case back
    case doubleBack

    var id: Self { self }

    var title: String {
        switch self {
        case .up: "D-pad Up"
        case .down: "D-pad Down"
        case .left: "D-pad Left"
        case .right: "D-pad Right"
        case .center: "Center"
        case .centerDouble: "Center, double tap"
        case .centerHold: "Center, hold"
        case .back: "Back"
        case .doubleBack: "Back, double tap"
        }
    }

    var symbol: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .center: "circle.inset.filled"
        case .centerDouble: "circle.circle.fill"
        case .centerHold: "hand.tap.fill"
        case .back: "arrow.uturn.backward"
        case .doubleBack: "arrow.uturn.backward.circle"
        }
    }

    /// The plain press a command maps to. Gestures are derived from timing.
    init?(command: RemoteCommand) {
        switch command {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .select: self = .center
        case .back: self = .back
        }
    }
}

enum MacAction: String, CaseIterable, Identifiable {
    case none
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    case scrollUp
    case scrollDown
    case scrollLeft
    case scrollRight
    case leftClick
    case doubleClick
    case rightClick
    case escape
    case keyboardShortcut
    case showDesktop
    case missionControl
    case toggleScrollMode

    var id: Self { self }

    /// Direction in Quartz coordinates, for the actions that are held.
    var vector: CGVector? {
        switch self {
        case .moveUp, .scrollUp: CGVector(dx: 0, dy: -1)
        case .moveDown, .scrollDown: CGVector(dx: 0, dy: 1)
        case .moveLeft, .scrollLeft: CGVector(dx: -1, dy: 0)
        case .moveRight, .scrollRight: CGVector(dx: 1, dy: 0)
        default: nil
        }
    }

    var isScroll: Bool {
        switch self {
        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight: true
        default: false
        }
    }

    var isHeld: Bool { vector != nil }

    /// The scrolling counterpart, used while scroll mode is on.
    var scrollEquivalent: MacAction {
        switch self {
        case .moveUp: .scrollUp
        case .moveDown: .scrollDown
        case .moveLeft: .scrollLeft
        case .moveRight: .scrollRight
        default: self
        }
    }

    var title: String {
        switch self {
        case .none: "Do Nothing"
        case .moveUp: "Move Pointer Up"
        case .moveDown: "Move Pointer Down"
        case .moveLeft: "Move Pointer Left"
        case .moveRight: "Move Pointer Right"
        case .scrollUp: "Scroll Up"
        case .scrollDown: "Scroll Down"
        case .scrollLeft: "Scroll Left"
        case .scrollRight: "Scroll Right"
        case .leftClick: "Left Click"
        case .doubleClick: "Double Click"
        case .rightClick: "Right Click"
        case .escape: "Escape"
        case .keyboardShortcut: "Keyboard Shortcut"
        case .showDesktop: "Show Desktop"
        case .missionControl: "Mission Control"
        case .toggleScrollMode: "Toggle Scrolling"
        }
    }

    var symbol: String {
        switch self {
        case .none: "nosign"
        case .moveUp: "arrow.up"
        case .moveDown: "arrow.down"
        case .moveLeft: "arrow.left"
        case .moveRight: "arrow.right"
        case .scrollUp: "arrow.up.to.line"
        case .scrollDown: "arrow.down.to.line"
        case .scrollLeft: "arrow.left.to.line"
        case .scrollRight: "arrow.right.to.line"
        case .leftClick: "cursorarrow.click"
        case .doubleClick: "cursorarrow.click.2"
        case .rightClick: "contextualmenu.and.cursorarrow"
        case .escape: "escape"
        case .keyboardShortcut: "keyboard"
        case .showDesktop: "macwindow"
        case .missionControl: "square.grid.3x2"
        case .toggleScrollMode: "arrow.up.and.down.text.horizontal"
        }
    }
}
