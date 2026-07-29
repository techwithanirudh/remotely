import AppKit
import ApplicationServices
import CoreGraphics

/// Marks every event this app posts, so a listener can tell a remote press from
/// the user's own mouse. CGEvent carries a spare user-data field for exactly
/// this; correlating by timestamp would only ever be a guess.
public enum EventSignature {
    public static let value: Int64 = 0x52_45_4D_42  // "REMB"

    public static func marks(_ event: NSEvent) -> Bool {
        event.cgEvent?.getIntegerValueField(.eventSourceUserData) == value
    }
}

/// Turns actions into system input.
@MainActor
public final class InputSynthesizer {
    private var pointer: ContinuousMotion?
    private var scroll: ContinuousMotion?

    public init() {}

    public static var hasAccessibility: Bool { AXIsProcessTrusted() }

    @discardableResult
    public static func requestAccessibility() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    /// One-shot actions. Continuous ones go through `hold`/`release`, which need
    /// the key-down duration rather than a single event.
    public func perform(_ binding: ButtonBinding) {
        switch binding.action {
        case .none, .toggleScrolling:
            break
        case .leftClick:
            click(.left, clicks: 1)
        case .doubleClick:
            click(.left, clicks: 2)
        case .rightClick:
            click(.right, clicks: 1)
        case .escape:
            press(key: 53)
        case .keyboardShortcut:
            if let combo = binding.combo { post(combo) }
        case .showDesktop:
            post(.showDesktop)
        case .missionControl:
            post(.missionControl)
        case .moveUp, .moveDown, .moveLeft, .moveRight,
             .scrollUp, .scrollDown, .scrollLeft, .scrollRight:
            nudge(binding.action)
        }
    }

    public func hold(_ action: RemoteAction, sensitivity: Double) {
        guard let direction = action.direction else { return }

        if action.isScroll {
            guard scroll?.direction != direction else { return }
            scroll = ContinuousMotion(direction: direction, glide: .scroll(sensitivity: sensitivity)) {
                [weak self] step in self?.postScroll(direction, distance: step)
            }
        } else {
            guard pointer?.direction != direction else { return }
            pointer = ContinuousMotion(direction: direction, glide: .pointer(sensitivity: sensitivity)) {
                [weak self] step in self?.movePointer(direction, distance: step)
            }
        }
    }

    public func release() {
        pointer?.stop()
        pointer = nil
        scroll?.stop()
        scroll = nil
    }
}

private extension InputSynthesizer {
    /// A tap still travels a little, by running the curve for a moment.
    func nudge(_ action: RemoteAction) {
        hold(action, sensitivity: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.release()
        }
    }

    func movePointer(_ direction: CGVector, distance: Double) {
        let current = CGEvent(source: nil)?.location ?? .zero
        let screen = CGRect(
            x: 0, y: 0,
            width: CGFloat(CGDisplayPixelsWide(CGMainDisplayID())),
            height: CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
        )
        let target = CGPoint(
            x: min(max(0, current.x + direction.dx * distance), screen.width - 1),
            y: min(max(0, current.y + direction.dy * distance), screen.height - 1)
        )

        let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        )
        send(event)
    }

    func postScroll(_ direction: CGVector, distance: Double) {
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(-direction.dy * distance),
            wheel2: Int32(-direction.dx * distance),
            wheel3: 0
        )
        send(event)
    }

    func click(_ button: CGMouseButton, clicks: Int64) {
        let at = CGEvent(source: nil)?.location ?? .zero
        let types: [CGEventType] = button == .right
            ? [.rightMouseDown, .rightMouseUp]
            : [.leftMouseDown, .leftMouseUp]

        for type in types {
            let event = CGEvent(
                mouseEventSource: nil,
                mouseType: type,
                mouseCursorPosition: at,
                mouseButton: button
            )
            event?.setIntegerValueField(.mouseEventClickState, value: clicks)
            send(event)
        }
    }

    /// Posts a recorded combination, then a bare event to restore modifier
    /// state. Mac Mouse Fix found that last step necessary: without it the
    /// system can believe modifiers are still held and fire the wrong hotkey.
    func post(_ combo: KeyCombo) {
        press(key: CGKeyCode(combo.keyCode), flags: combo.flags)
        send(CGEvent(source: nil))
    }

    func post(_ hotKey: SymbolicHotKey) {
        guard let shortcut = hotKey.shortcut else { return }
        press(key: shortcut.key, flags: shortcut.flags)
        send(CGEvent(source: nil))
    }

    func press(key: CGKeyCode, flags: CGEventFlags = []) {
        for isDown in [true, false] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: isDown)
            event?.flags = flags
            send(event)
        }
    }

    func send(_ event: CGEvent?) {
        event?.setIntegerValueField(.eventSourceUserData, value: EventSignature.value)
        event?.post(tap: .cghidEventTap)
    }
}

/// Drives one direction until released.
@MainActor
private final class ContinuousMotion {
    let direction: CGVector

    private var glide: Glide
    private var timer: Timer?

    private let step: (Double) -> Void

    init(direction: CGVector, glide: Glide, step: @escaping (Double) -> Void) {
        self.direction = direction
        self.glide = glide
        self.step = step

        // Common modes: an open menu spins a nested tracking run loop, and a
        // timer scheduled the ordinary way stops firing while it is up.
        let timer = Timer(timeInterval: Glide.tick, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advance() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        advance()
    }

    private func advance() {
        step(glide.advance())
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
