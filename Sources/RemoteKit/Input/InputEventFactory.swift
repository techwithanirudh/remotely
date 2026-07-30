import CoreGraphics

package enum InputEventFactory {
    package static func scroll(
        direction: CGVector,
        distance: Double,
        units: CGScrollEventUnit = .pixel
    ) -> CGEvent? {
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: units,
            wheelCount: 2,
            wheel1: Int32(-direction.dy * distance),
            wheel2: Int32(-direction.dx * distance),
            wheel3: 0
        )
        event?.location = CGEvent(source: nil)?.location ?? .zero
        return event
    }

    package static func mouseClick(
        button: CGMouseButton,
        location: CGPoint,
        clicks: Int64
    ) -> [CGEvent] {
        guard clicks > 0 else { return [] }
        let types: [CGEventType] = switch button {
        case .left: [.leftMouseDown, .leftMouseUp]
        case .right: [.rightMouseDown, .rightMouseUp]
        default: [.otherMouseDown, .otherMouseUp]
        }

        return (1 ... clicks).flatMap { click in
            types.compactMap { type in
                let event = CGEvent(
                    mouseEventSource: nil,
                    mouseType: type,
                    mouseCursorPosition: location,
                    mouseButton: button
                )
                event?.setIntegerValueField(.mouseEventClickState, value: click)
                return event
            }
        }
    }
}
