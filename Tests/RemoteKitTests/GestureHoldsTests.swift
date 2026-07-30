import CoreGraphics
import Foundation
import RemoteKit

func gestureHoldsTests() {
    Expect.suite("Gesture holds") {
        do {
            var reader = GestureReader()
            _ = reader.press(.select, at: 0)
            Expect.equal(reader.elapse(to: 0.3), [], "a hold has not qualified yet at 0.3s")
            Expect.equal(reader.elapse(to: 0.6), [.trigger(.centerHold)],
                         "a hold fires while the key is still down")
            Expect.equal(reader.release(at: 0.9), [],
                         "the release after a hold does not also click")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.back, at: 0)
            Expect.equal(
                reader.elapse(to: 0.6),
                [.trigger(.backHold)],
                "holding Back has its own binding"
            )
            Expect.equal(reader.release(at: 0.7), [],
                         "releasing a held Back does not also fire its press")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.back, at: 0)
            Expect.equal(reader.release(at: 0.05), [.triggerDeferred(.back, after: 0.30)],
                         "a single Back waits out the double-tap window")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.back, at: 0)
            _ = reader.release(at: 0.05)
            _ = reader.press(.back, at: 0.1)
            Expect.equal(reader.release(at: 0.15), [.cancelDeferred, .trigger(.backDouble)],
                         "a second Back cancels the pending single press")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.left, at: 0)
            Expect.equal(reader.elapse(to: 0.3), [], "a live hold keeps running")
            Expect.equal(reader.elapse(to: 1.0), [.endHold],
                         "a dropped release stops motion once repeats go quiet")
            Expect.that(reader.heldKey == nil, "the held key is cleared after recovery")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.left, at: 0)
            Expect.equal(reader.press(.right, at: 0.2), [.endHold, .beginHold(.right)],
                         "pressing another arrow ends the previous hold")
        }
    }
}

/// The suite drove holds with one jump to 0.6s. The app ticks every 0.05s while
/// CEC repeats the key, so the repeats have to not reset the hold.
func gestureHoldTickTests() {
    Expect.suite("Gesture holds under the real tick") {
        var reader = GestureReader()
        var events: [GestureReader.Event] = []

        _ = reader.press(.back, at: 0)
        var now = 0.0
        var nextRepeat = 0.1
        while now < 0.8 {
            now += 0.05
            if now >= nextRepeat {
                events += reader.press(.back, at: now)
                nextRepeat += 0.1
            }
            events += reader.elapse(to: now)
        }

        Expect.equal(events, [.trigger(.backHold)],
                     "holding Back fires once, and the repeats do not reset it")
    }
}
