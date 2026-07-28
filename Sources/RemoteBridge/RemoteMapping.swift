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
    case leftClick
    case doubleClick
    case rightClick
    case browserBack
    case showDesktop
    case missionControl

    var id: Self { self }

    var title: String {
        switch self {
        case .none: "Do Nothing"
        case .moveUp: "Move Pointer Up"
        case .moveDown: "Move Pointer Down"
        case .moveLeft: "Move Pointer Left"
        case .moveRight: "Move Pointer Right"
        case .leftClick: "Left Click"
        case .doubleClick: "Double Click"
        case .rightClick: "Right Click"
        case .browserBack: "Browser Back"
        case .showDesktop: "Show Desktop"
        case .missionControl: "Mission Control"
        }
    }

    var symbol: String {
        switch self {
        case .none: "nosign"
        case .moveUp: "arrow.up"
        case .moveDown: "arrow.down"
        case .moveLeft: "arrow.left"
        case .moveRight: "arrow.right"
        case .leftClick: "cursorarrow.click"
        case .doubleClick: "cursorarrow.click.2"
        case .rightClick: "contextualmenu.and.cursorarrow"
        case .browserBack: "chevron.backward"
        case .showDesktop: "macwindow"
        case .missionControl: "square.grid.3x2"
        }
    }
}

extension Dictionary where Key == RemoteButton, Value == MacAction {
    static var defaultRemoteMappings: Self {
        [
            .up: .moveUp,
            .down: .moveDown,
            .left: .moveLeft,
            .right: .moveRight,
            .center: .leftClick,
            .centerDouble: .doubleClick,
            .centerHold: .rightClick,
            .back: .browserBack,
            .doubleBack: .showDesktop,
        ]
    }
}
