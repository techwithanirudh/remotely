import AppKit
import RemoteKit
import SwiftUI

enum PracticeExercise {
    case move, click, doubleClick, rightClick, scroll

    var title: String {
        switch self {
        case .move: "Hold an arrow to move the pointer"
        case .click: "Press Center to click"
        case .doubleClick: "Press Center twice to double-click"
        case .rightClick: "Hold Center for a right click"
        case .scroll: "Press Back twice to scroll"
        }
    }

    var hint: String {
        switch self {
        case .move: "Holding speeds up the longer you hold. A quick tap nudges a few pixels."
        case .click: "Move onto something first, then press Center once."
        case .doubleClick: "Two quick presses, the gesture that opens files and folders."
        case .rightClick: "Keep Center held for about half a second."
        case .scroll: "That switches the arrows between moving the pointer and scrolling."
        }
    }

    var symbol: String {
        switch self {
        case .move: RemoteAction.moveUp.symbol
        case .click: RemoteAction.leftClick.symbol
        case .doubleClick: "cursorarrow.rays"
        case .rightClick: "contextualmenu.and.cursorarrow"
        case .scroll: RemoteAction.toggleScrolling.symbol
        }
    }

    var tint: Color {
        switch self {
        case .move: .blue
        case .click: .purple
        case .doubleClick: .pink
        case .rightClick: .indigo
        case .scroll: .teal
        }
    }

    var idleSymbol: String {
        switch self {
        case .move: "scope"
        case .click: "cursorarrow"
        case .doubleClick: "2.circle"
        case .rightClick: "hand.point.up.left"
        case .scroll: "arrow.up.arrow.down"
        }
    }

    var prompt: String {
        switch self {
        case .move: "Move the pointer with an arrow"
        case .click: "Press Center once"
        case .doubleClick: "Press Center twice, quickly"
        case .rightClick: "Hold Center to open a menu here"
        case .scroll: "Scroll this list"
        }
    }

    var mask: NSEvent.EventTypeMask {
        switch self {
        case .move: .mouseMoved
        case .click, .doubleClick: .leftMouseDown
        case .rightClick: [.rightMouseDown, .leftMouseDown]
        case .scroll: [.scrollWheel, .mouseMoved]
        }
    }

    func judge(_ event: NSEvent, fromRemote: Bool, insideTarget: Bool) -> PracticeOutcome? {
        switch self {
        case .move:
            return fromRemote ? .passed : nil

        case .scroll:
            guard fromRemote else { return .wrong(Self.wrongSource) }
            if event.type == .scrollWheel { return .passed }
            return insideTarget
                ? .wrong("Still moving the pointer. Press Back twice first.")
                : nil

        case .click, .doubleClick, .rightClick:
            guard insideTarget else { return nil }
            guard fromRemote else { return .wrong(Self.wrongSource) }
            return verdict(for: event)
        }
    }

    private static let wrongSource = "That was your mouse, not the remote."

    private func verdict(for event: NSEvent) -> PracticeOutcome {
        switch self {
        case .click:
            event.clickCount >= 2
                ? .wrong("That was a double press. Try one on its own.")
                : .passed
        case .doubleClick:
            event.clickCount >= 2
                ? .passed
                : .wrong("Only one press registered. Press again faster.")
        default:
            event.type == .rightMouseDown
                ? .passed
                : .wrong("That was a normal click. Hold Center longer.")
        }
    }
}
