// Derived from Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix),
// which is under the MMF License, not MIT like the rest of this repository:
// https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License
//
// Its conditions attach to publishing a program whose source is copied or
// derived from theirs, so read it before this app is distributed.

import CoreGraphics

/// The two-finger swipe a trackpad sends to go back or forward.
///
/// No private framework: the event is an ordinary CGEvent with undocumented
/// integer fields set on it. 55 is the NSEvent type, 110 the IOHID event type,
/// 132 the phase and 115 the direction. Values are from IOKit's own
/// `IOHIDEventTypes.h`, which is where Mac Mouse Fix reads them too.
enum NavigationSwipe {
    private static let gestureEventType: Int64 = 29
    private static let navigationSwipe: Int64 = 16
    private static let phaseBegan: Int64 = 1
    private static let phaseEnded: Int64 = 4
    private static let swipeNone: Int64 = 0

    enum Direction: Int64 {
        case left = 4
        case right = 8
    }

    /// The four fields the gesture is assembled from. Not in the public
    /// CGEventField enum, so they are built from their raw values.
    private enum Field {
        static let eventType = CGEventField(rawValue: 55)
        static let hidType = CGEventField(rawValue: 110)
        static let phase = CGEventField(rawValue: 132)
        static let direction = CGEventField(rawValue: 115)
    }

    static func post(_ direction: Direction) {
        guard let event = CGEvent(source: nil) else { return }

        guard let eventType = Field.eventType, let hidType = Field.hidType,
              let phase = Field.phase, let directionField = Field.direction
        else { return }

        event.setIntegerValueField(eventType, value: gestureEventType)
        event.setIntegerValueField(hidType, value: navigationSwipe)
        event.setIntegerValueField(phase, value: phaseBegan)
        event.setIntegerValueField(directionField, value: direction.rawValue)
        event.post(tap: .cghidEventTap)

        event.setIntegerValueField(directionField, value: swipeNone)
        event.setIntegerValueField(phase, value: phaseEnded)
        event.post(tap: .cghidEventTap)
    }
}
