import CoreGraphics
import RemotelyKit

private struct ScrollCase {
    let action: RemoteAction
    let units: CGScrollEventUnit
    let distance: Double
    let field: CGEventField
    let expected: Int64
}

func inputEventsTests() {
    Expect.suite("Synthetic input") {
        checkScrollEvents()
        checkNavigationButtons()
        checkDoubleClick()
    }
}

private func checkScrollEvents() {
    let cases = [
        ScrollCase(
            action: .scrollUp,
            units: .line,
            distance: 3,
            field: .scrollWheelEventDeltaAxis1,
            expected: 3
        ),
        ScrollCase(
            action: .scrollDown,
            units: .line,
            distance: 3,
            field: .scrollWheelEventDeltaAxis1,
            expected: -3
        ),
        ScrollCase(
            action: .scrollLeft,
            units: .pixel,
            distance: 120,
            field: .scrollWheelEventPointDeltaAxis2,
            expected: 120
        ),
        ScrollCase(
            action: .scrollRight,
            units: .pixel,
            distance: 120,
            field: .scrollWheelEventPointDeltaAxis2,
            expected: -120
        ),
    ]

    for testCase in cases {
        let event = testCase.action.direction.flatMap {
            InputEventFactory.scroll(
                direction: $0,
                distance: testCase.distance,
                units: testCase.units
            )
        }
        Expect.equal(
            event?.getIntegerValueField(testCase.field),
            testCase.expected,
            "\(testCase.action.title) has the right delta"
        )
    }
}

private func checkNavigationButtons() {
    let back = InputEventFactory.mouseClick(
        button: CGMouseButton(rawValue: 3) ?? .center,
        location: .zero,
        clicks: 1
    ).first
    let forward = InputEventFactory.mouseClick(
        button: CGMouseButton(rawValue: 4) ?? .center,
        location: .zero,
        clicks: 1
    ).first
    Expect.equal(back?.getIntegerValueField(.mouseEventButtonNumber), 3,
                 "Back posts mouse button 4")
    Expect.equal(forward?.getIntegerValueField(.mouseEventButtonNumber), 4,
                 "Forward posts mouse button 5")
}

private func checkDoubleClick() {
    let doubleClick = InputEventFactory.mouseClick(
        button: .left,
        location: .zero,
        clicks: 2
    )
    Expect.equal(doubleClick.count, 4, "a double-click has two down/up pairs")
    Expect.equal(
        doubleClick.map { $0.getIntegerValueField(.mouseEventClickState) },
        [1, 1, 2, 2],
        "double-click levels match native mouse sequencing"
    )
}
