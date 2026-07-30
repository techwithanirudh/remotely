import CoreGraphics
import Foundation
import RemoteKit

func actionsTests() {
    Expect.suite("Actions") {
        Expect.equal(
            RemoteAction.moveUp.scrolling,
            .scrollUp,
            "moving maps to its scrolling counterpart"
        )
        Expect.equal(
            RemoteAction.leftClick.scrolling,
            .leftClick,
            "a click is unaffected by scroll mode"
        )
        Expect.equal(
            Set(RemoteAction.Group.allCases.flatMap(\.actions)),
            Set(RemoteAction.allCases),
            "every action appears in exactly one picker section"
        )
        Expect.equal(
            RemoteAction.Group.allCases.flatMap(\.actions).count,
            RemoteAction.allCases.count,
            "no action is listed in two sections"
        )
        Expect.that(RemoteAction.moveLeft.isContinuous, "movement is continuous")
        Expect.that(!RemoteAction.escape.isContinuous, "Escape is a one-shot")
        Expect.equal(RemoteAction.scrollDown.direction, CGVector(dx: 0, dy: 1), "down points down")
        Expect.that(!RemoteAction.middleClick.isContinuous, "a middle click is a one-shot")
        Expect.that(!RemoteAction.browserBack.isContinuous, "Back is a one-shot")
        Expect.equal(RemoteAction.browserForward.scrolling, .browserForward,
                     "scroll mode leaves Forward alone")
        Expect.that(
            Set(RemoteAction.allCases.map(\.title)).count == RemoteAction.allCases.count,
            "every action has a distinct name in the picker"
        )
    }
}
