import RemoteKit

func gestureRulesTests() {
    Expect.suite("Gesture rules") {
        do {
            var reader = GestureReader()
            Expect.equal(reader.press(.right, at: 0), [.beginHold(.right)],
                         "a held arrow starts motion")
            Expect.equal(reader.press(.right, at: 0.1), [],
                         "repeats keep the hold alive without restarting it")
            Expect.equal(reader.release(at: 0.4), [.endHold],
                         "releasing stops motion")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.select, at: 0)
            Expect.equal(reader.release(at: 0.1), [.trigger(.center)],
                         "a quick Center press clicks")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.select, at: 0)
            _ = reader.release(at: 0.05)
            _ = reader.press(.select, at: 0.1)
            Expect.equal(reader.release(at: 0.15), [.trigger(.centerDouble)],
                         "two quick Center presses double-click")
        }

        do {
            var reader = GestureReader()
            _ = reader.press(.select, at: 0)
            _ = reader.release(at: 0.05)
            _ = reader.press(.select, at: 5)
            Expect.equal(reader.release(at: 5.05), [.trigger(.center)],
                         "presses far apart stay single clicks")
        }
    }
}
