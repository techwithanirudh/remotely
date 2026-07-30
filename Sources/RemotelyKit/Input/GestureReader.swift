import Foundation

/// A press repeats while the key is held and ends with a single release that
/// carries no key code. Timing must distinguish taps, double taps and holds, so
/// callers drive this pure state machine with `press`, `release` and `elapse`.
public struct GestureReader: Sendable {
    public struct Config: Sendable {
        public var holdThreshold: TimeInterval
        public var doubleTapWindow: TimeInterval
        /// How long after the last repeat a held key is assumed released. CEC
        /// occasionally drops the release entirely.
        public var repeatTimeout: TimeInterval

        public init(
            holdThreshold: TimeInterval = 0.5,
            doubleTapWindow: TimeInterval = 0.30,
            repeatTimeout: TimeInterval = 0.6
        ) {
            self.holdThreshold = holdThreshold
            self.doubleTapWindow = doubleTapWindow
            self.repeatTimeout = repeatTimeout
        }
    }

    public enum Event: Equatable, Sendable {
        /// A continuous action should start; it runs until `endHold`.
        case beginHold(RemoteButton)
        case endHold
        case trigger(RemoteButton)
        /// A single tap that must wait out the double-tap window first.
        case triggerDeferred(RemoteButton, after: TimeInterval)
        case cancelDeferred
    }

    public private(set) var heldKey: RemoteKey?

    private var config: Config
    private var now: TimeInterval = 0
    private var pressedAt: TimeInterval = 0
    private var lastRepeatAt: TimeInterval = 0
    private var lastTapAt: TimeInterval = -.greatestFiniteMagnitude
    private var holdFired = false

    public init(config: Config = Config()) {
        self.config = config
    }

    public mutating func press(_ key: RemoteKey, at time: TimeInterval) -> [Event] {
        now = time

        // Repeats only keep the hold alive; motion is already running.
        if key == heldKey {
            lastRepeatAt = time
            return []
        }

        var events = finish(released: false)
        heldKey = key
        pressedAt = time
        lastRepeatAt = time
        holdFired = false

        if key.isDirectional, let button = RemoteButton(key: key) {
            events.append(.beginHold(button))
        }
        return events
    }

    public mutating func release(at time: TimeInterval) -> [Event] {
        now = time
        return finish(released: true)
    }

    /// Advances time without an incoming event, firing a hold once it qualifies
    /// and dropping a held key whose repeats have gone quiet.
    public mutating func elapse(to time: TimeInterval) -> [Event] {
        now = time
        guard let key = heldKey else { return [] }

        if !key.isDirectional, !holdFired, time - pressedAt >= config.holdThreshold {
            holdFired = true
            switch key {
            case .select: return [.trigger(.centerHold)]
            case .back: return [.trigger(.backHold)]
            default: return []
            }
        }

        if time - lastRepeatAt > config.repeatTimeout {
            return finish(released: false)
        }
        return []
    }
}

private extension GestureReader {
    mutating func finish(released: Bool) -> [Event] {
        guard let key = heldKey else { return [] }
        heldKey = nil

        if key.isDirectional {
            return [.endHold]
        }

        // The hold already fired while the key was down; the release that
        // follows must not also register a tap.
        if holdFired {
            holdFired = false
            return []
        }
        guard released else { return [] }

        switch key {
        case .select:
            return [.trigger(isDoubleTap() ? .centerDouble : .center)]
        case .back:
            if isDoubleTap() {
                return [.cancelDeferred, .trigger(.backDouble)]
            }
            return [.triggerDeferred(.back, after: config.doubleTapWindow)]
        default:
            return []
        }
    }

    mutating func isDoubleTap() -> Bool {
        defer { lastTapAt = now }
        return now - lastTapAt < config.doubleTapWindow
    }
}
