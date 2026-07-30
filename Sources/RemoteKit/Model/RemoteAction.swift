import CoreGraphics

/// What a button does once pressed.
public enum RemoteAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case none
    case moveUp, moveDown, moveLeft, moveRight
    case scrollUp, scrollDown, scrollLeft, scrollRight
    case leftClick, doubleClick, rightClick, middleClick
    case browserBack, browserForward
    case escape
    case keyboardShortcut
    case showDesktop, missionControl
    case toggleScrolling

    public var id: Self { self }

    /// Sections in the picker. Twenty flat items was a wall of text; Mac Mouse
    /// Fix separates its menu the same way.
    public enum Group: CaseIterable, Sendable {
        case pointer, scrolling, clicks, navigation, system, other

        public var actions: [RemoteAction] {
            switch self {
            case .pointer: [.moveUp, .moveDown, .moveLeft, .moveRight]
            case .scrolling: [.scrollUp, .scrollDown, .scrollLeft, .scrollRight, .toggleScrolling]
            case .clicks: [.leftClick, .doubleClick, .rightClick, .middleClick]
            case .navigation: [.browserBack, .browserForward]
            case .system: [.showDesktop, .missionControl, .escape]
            case .other: [.keyboardShortcut, .none]
            }
        }
    }

    public var title: String {
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
        case .middleClick: "Middle Click"
        case .browserBack: "Back"
        case .browserForward: "Forward"
        case .escape: "Escape"
        case .keyboardShortcut: "Keyboard Shortcut"
        case .showDesktop: "Show Desktop"
        case .missionControl: "Mission Control"
        case .toggleScrolling: "Toggle Scrolling"
        }
    }

    public var symbol: String {
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
        case .middleClick: "cursorarrow.click.badge.clock"
        case .browserBack: "chevron.backward"
        case .browserForward: "chevron.forward"
        case .escape: "escape"
        case .keyboardShortcut: "keyboard"
        case .showDesktop: "macwindow"
        case .missionControl: "square.grid.3x2"
        case .toggleScrolling: "arrow.up.and.down.text.horizontal"
        }
    }

    /// Direction in Quartz coordinates, for the actions driven by a held key.
    public var direction: CGVector? {
        switch self {
        case .moveUp, .scrollUp: CGVector(dx: 0, dy: -1)
        case .moveDown, .scrollDown: CGVector(dx: 0, dy: 1)
        case .moveLeft, .scrollLeft: CGVector(dx: -1, dy: 0)
        case .moveRight, .scrollRight: CGVector(dx: 1, dy: 0)
        default: nil
        }
    }

    public var isScroll: Bool {
        switch self {
        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight: true
        default: false
        }
    }

    public var isContinuous: Bool { direction != nil }

    /// The scrolling counterpart, used while scroll mode is on.
    public var scrolling: RemoteAction {
        switch self {
        case .moveUp: .scrollUp
        case .moveDown: .scrollDown
        case .moveLeft: .scrollLeft
        case .moveRight: .scrollRight
        default: self
        }
    }
}
