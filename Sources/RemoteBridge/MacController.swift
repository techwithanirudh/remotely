import AppKit
import ApplicationServices
import Carbon.HIToolbox
import RemoteCore

/// Injects pointer and keyboard events.
///
/// Pointer motion follows the model TV virtual-mouse implementations converge
/// on (MATVT, DPTV-Cursor): a press starts a timer that moves the cursor a very
/// small amount per tick and ramps the speed up the longer the key is held.
/// A quick tap therefore nudges by a few pixels — enough to hit a menu item —
/// while holding glides across the screen. Fixed per-press jumps cannot do both.

/// Stamped onto every event this app injects, so a listener can tell a remote
/// press apart from the user's own mouse. CGEvent carries a spare user-data
/// field for exactly this; timing correlation would only ever be a guess.
enum RemoteEventSignature {
    static let value: Int64 = 0x52_45_4D_42  // "REMB"

    static func marks(_ event: NSEvent) -> Bool {
        event.cgEvent?.getIntegerValueField(.eventSourceUserData) == value
    }
}

@MainActor
final class MacController {
    /// Speed the cursor starts at, in points per second.
    private static let initialSpeed: Double = 95
    /// How quickly held movement ramps up, in points per second squared.
    private static let acceleration: Double = 1500
    private static let maximumSpeed: Double = 2700
    private static let tickInterval: TimeInterval = 1.0 / 60.0

    private var moveVector: CGVector?
    private var speed: Double = 0
    private var moveTimer: Timer?

    private var scrollVector: CGVector?
    private var scrollSpeed: Double = 0
    private var scrollTimer: Timer?

    func requestAccessibilityPermission() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Discrete actions. Movement is driven by `beginHold`/`endHold` instead,
    /// because it needs the key-down duration rather than a one-shot event.
    func perform(_ action: MacAction, shortcut: KeyboardShortcut? = nil, sensitivity: Double = 1) {
        switch action {
        case .none, .toggleScrollMode: break
        case .keyboardShortcut:
            if let shortcut { postShortcut(shortcut) }
        case .leftClick: click(button: .left, clickState: 1)
        case .doubleClick: click(button: .left, clickState: 2)
        case .rightClick: click(button: .right, clickState: 1)
        case .escape: pressKey(53)
        case .showDesktop: pressKey(103) // F11
        case .missionControl: pressKey(126, flags: .maskControl) // Control-Up
        case .moveUp, .moveDown, .moveLeft, .moveRight,
             .scrollUp, .scrollDown, .scrollLeft, .scrollRight:
            beginHold(action, sensitivity: sensitivity)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.endHold()
            }
        }
    }

    /// Starts continuous movement or scrolling for as long as the key is held.
    func beginHold(_ action: MacAction, sensitivity: Double) {
        guard let vector = action.vector else { return }

        if action.isScroll {
            guard scrollVector != vector else { return }
            scrollVector = vector
            scrollSpeed = Self.initialSpeed * sensitivity * 0.35
            startScrollTimer(sensitivity: sensitivity)
        } else {
            guard moveVector != vector else { return }
            moveVector = vector
            speed = Self.initialSpeed * sensitivity
            startMoveTimer(sensitivity: sensitivity)
        }
    }

    func endHold() {
        moveTimer?.invalidate()
        moveTimer = nil
        moveVector = nil
        speed = 0

        scrollTimer?.invalidate()
        scrollTimer = nil
        scrollVector = nil
        scrollSpeed = 0
    }

    private func startMoveTimer(sensitivity: Double) {
        guard moveTimer == nil else { return }
        moveTimer = Self.makeTimer { [weak self] in self?.stepMove(sensitivity: sensitivity) }
        stepMove(sensitivity: sensitivity)
    }

    /// Runs in the common modes rather than the default one.
    ///
    /// An open menu spins a nested event-tracking run loop, and a timer
    /// scheduled the ordinary way stops firing for as long as it is up: the
    /// pointer froze the moment a context menu appeared.
    private static func makeTimer(_ tick: @escaping @MainActor () -> Void) -> Timer {
        let timer = Timer(timeInterval: tickInterval, repeats: true) { _ in
            MainActor.assumeIsolated { tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func stepMove(sensitivity: Double) {
        guard let vector = moveVector else { return }
        let distance = speed * Self.tickInterval
        speed = min(speed + Self.acceleration * sensitivity * Self.tickInterval,
                    Self.maximumSpeed * sensitivity)

        let current = CGEvent(source: nil)?.location ?? .zero
        let bounds = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(CGDisplayPixelsWide(CGMainDisplayID())),
            height: CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
        )
        let target = CGPoint(
            x: min(max(0, current.x + vector.dx * distance), bounds.width - 1),
            y: min(max(0, current.y + vector.dy * distance), bounds.height - 1)
        )
        let move = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        )
        move?.setIntegerValueField(.eventSourceUserData, value: RemoteEventSignature.value)
        move?.post(tap: .cghidEventTap)
    }

    private func startScrollTimer(sensitivity: Double) {
        guard scrollTimer == nil else { return }
        scrollTimer = Self.makeTimer { [weak self] in self?.stepScroll(sensitivity: sensitivity) }
        stepScroll(sensitivity: sensitivity)
    }

    private func stepScroll(sensitivity: Double) {
        guard let vector = scrollVector else { return }
        let distance = scrollSpeed * Self.tickInterval
        scrollSpeed = min(scrollSpeed + Self.acceleration * 0.35 * sensitivity * Self.tickInterval,
                          Self.maximumSpeed * 0.35 * sensitivity)

        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(-vector.dy * distance),
            wheel2: Int32(-vector.dx * distance),
            wheel3: 0
        )
        event?.setIntegerValueField(.eventSourceUserData, value: RemoteEventSignature.value)
        event?.post(tap: .cghidEventTap)
    }

    private func click(button: CGMouseButton, clickState: Int64) {
        let point = CGEvent(source: nil)?.location ?? .zero
        let types: (CGEventType, CGEventType) = button == .right
            ? (.rightMouseDown, .rightMouseUp)
            : (.leftMouseDown, .leftMouseUp)

        for type in [types.0, types.1] {
            let event = CGEvent(
                mouseEventSource: nil,
                mouseType: type,
                mouseCursorPosition: point,
                mouseButton: button
            )
            event?.setIntegerValueField(.mouseEventClickState, value: clickState)
            event?.setIntegerValueField(.eventSourceUserData, value: RemoteEventSignature.value)
            event?.post(tap: .cghidEventTap)
        }
    }

    /// Posts a recorded combination.
    ///
    /// The trailing bare event restores modifier state. Mac Mouse Fix does the
    /// same, having found that leaving it out makes the system believe
    /// modifiers are still held and fire the wrong hotkey.
    private func postShortcut(_ shortcut: KeyboardShortcut) {
        pressKey(CGKeyCode(shortcut.keyCode), flags: shortcut.eventFlags)

        let restore = CGEvent(source: nil)
        restore?.setIntegerValueField(.eventSourceUserData, value: RemoteEventSignature.value)
        restore?.post(tap: .cghidEventTap)
    }

    private func pressKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.setIntegerValueField(.eventSourceUserData, value: RemoteEventSignature.value)
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.setIntegerValueField(.eventSourceUserData, value: RemoteEventSignature.value)
        up?.post(tap: .cghidEventTap)
    }
}
