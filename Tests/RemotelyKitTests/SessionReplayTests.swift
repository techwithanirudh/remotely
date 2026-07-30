import Foundation
import RemotelyKit

/// Replays a real capture: 18 Back presses off a Hisense M70D, 7 held and 11
/// tapped, two of those close enough to read as one double tap. A hand-written
/// sequence would only assert what we believed the hardware did.
func sessionReplayTests() {
    Expect.suite("Recorded session replay") {
        guard let lines = fixture() else {
            Expect.that(false, "the recorded session fixture is readable")
            return
        }

        let outcome = replay(lines)

        Expect.equal(outcome.triggered.count(where: { $0 == .backHold }), 7,
                     "all seven held Backs in the capture fire the hold")
        Expect.equal(outcome.triggered.count(where: { $0 == .backDouble }), 2,
                     "two taps landed inside the double-tap window")
        Expect.equal(outcome.deferred.count(where: { $0 == .back }), 9,
                     "the other nine taps each wait out the double-tap window")
        Expect.that(!outcome.triggered.contains(.back),
                    "a held Back never also fires a tap")
    }
}

private struct Outcome {
    var triggered: [RemoteButton] = []
    var deferred: [RemoteButton] = []

    mutating func record(_ events: [GestureReader.Event]) {
        for event in events {
            switch event {
            case .trigger(let button): triggered.append(button)
            case .triggerDeferred(let button, _): deferred.append(button)
            default: break
            }
        }
    }
}

private func replay(_ lines: [(TimeInterval, String)]) -> Outcome {
    let parser = CECLogParser()
    var reader = GestureReader()
    var outcome = Outcome()
    var pressedAt: TimeInterval?

    for (time, line) in lines {
        guard let parsed = parser.parse(line) else { continue }
        var events: [GestureReader.Event] = []

        switch parsed {
        case .pressed(let key):
            pressedAt = time
            events = reader.press(key, at: time)
        case .released:
            // Holds fire from `elapse`, so the ticks have to be replayed too.
            if let start = pressedAt {
                var tick = start
                while tick < time {
                    tick += 0.05
                    events += reader.elapse(to: min(tick, time))
                }
            }
            events += reader.release(at: time)
            pressedAt = nil
        case .attached:
            continue
        }

        outcome.record(events)
    }
    return outcome
}

private func fixture() -> [(TimeInterval, String)]? {
    let path = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/back-tap-and-hold.txt")
    guard let text = try? String(contentsOf: path, encoding: .utf8) else { return nil }

    return text.split(separator: "\n").compactMap { line in
        let fields = line.split(separator: " ")
        guard fields.count > 1 else { return nil }
        let parts = fields[1].split(separator: ":")
        guard parts.count == 3, let hour = Double(parts[0]), let minute = Double(parts[1]),
              let second = Double(parts[2])
        else { return nil }
        return (hour * 3600 + minute * 60 + second, String(line))
    }
}
