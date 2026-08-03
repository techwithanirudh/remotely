import AppKit
import ApplicationServices
import CoreGraphics

/// Marks every event this app posts, so onboarding can tell a remote press from
/// the user's own mouse.
public enum EventSignature {
    public static let value: Int64 = 0x5245_4D42 // "REMB"

    public static func marks(_ event: NSEvent) -> Bool {
        event.cgEvent?.getIntegerValueField(.eventSourceUserData) == value
    }
}

@MainActor
public final class InputSynthesizer {
    private static let clickHold = 0.07

    private var pointer: ContinuousMotion?
    private var scroll: ContinuousMotion?

    private var scrollPixels = PixelAccumulator()

    /// Where the pointer is being driven to, in full precision. Reading it back
    /// from the window server each frame rounded to whole pixels.
    private var pointerTarget: CGPoint?

    /// Nothing reports which app took a posted event, so the choice says so.
    public private(set) var lastNavigation = ""

    public init() {}

    public static var hasAccessibility: Bool { AXIsProcessTrusted() }

    @discardableResult
    public static func requestAccessibility() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    public func perform(_ binding: ButtonBinding) {
        perform(binding, targetApp: nil, navigationMethod: nil)
    }

    package func perform(
        _ binding: ButtonBinding,
        targetApp: String?,
        navigationMethod: NavigationMethod? = nil
    ) {
        lastNavigation = ""
        switch binding.action {
        case .none, .toggleScrolling:
            break
        case .leftClick, .doubleClick, .rightClick,
             .middleClick, .browserBack, .browserForward:
            click(
                binding.action,
                targetApp: targetApp,
                navigationMethod: navigationMethod
            )
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
            scroll = ContinuousMotion(
                direction: direction,
                glide: .scroll(sensitivity: sensitivity)
            ) { [weak self] step in
                self?.postScroll(direction, distance: step)
            }
        } else {
            guard pointer?.direction != direction else { return }
            pointer = ContinuousMotion(
                direction: direction,
                glide: .pointer(sensitivity: sensitivity)
            ) { [weak self] step in
                self?.movePointer(direction, distance: step)
            }
        }
    }

    public func release() {
        pointer?.stop()
        pointer = nil
        scroll?.stop()
        scroll = nil
        pointerTarget = nil
        scrollPixels.reset()
    }
}

private extension InputSynthesizer {
    func nudge(_ action: RemoteAction) {
        if action.isScroll, let direction = action.direction {
            let horizontal = direction.dx != 0
            postScroll(
                direction,
                distance: horizontal ? 120 : 3,
                units: horizontal ? .pixel : .line
            )
            return
        }

        hold(action, sensitivity: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.release()
        }
    }

    func movePointer(_ direction: CGVector, distance: Double) {
        let current = pointerTarget ?? CGEvent(source: nil)?.location ?? .zero
        let screen = CGRect(
            x: 0, y: 0,
            width: CGFloat(CGDisplayPixelsWide(CGMainDisplayID())),
            height: CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
        )
        let target = CGPoint(
            x: min(max(0, current.x + direction.dx * distance), screen.width - 1),
            y: min(max(0, current.y + direction.dy * distance), screen.height - 1)
        )

        pointerTarget = target
        let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        )
        send(event)
    }

    func postScroll(
        _ direction: CGVector,
        distance: Double,
        units: CGScrollEventUnit = .pixel
    ) {
        guard units == .pixel else {
            send(
                InputEventFactory.scroll(direction: direction, distance: distance, units: units),
                tap: .cgSessionEventTap
            )
            return
        }

        let step = CGVector(dx: direction.dx * distance, dy: direction.dy * distance)
        guard let whole = scrollPixels.take(step) else { return }
        send(
            InputEventFactory.scroll(direction: whole, distance: 1, units: .pixel),
            tap: .cgSessionEventTap
        )
    }

    func click(
        _ action: RemoteAction,
        targetApp: String?,
        navigationMethod: NavigationMethod?
    ) {
        switch action {
        case .leftClick: click(.left, clicks: 1)
        case .doubleClick: click(.left, clicks: 2)
        case .rightClick: click(.right, clicks: 1)
        case .middleClick: click(.center, clicks: 1)
        case .browserBack:
            navigate(back: true, targetApp: targetApp, method: navigationMethod)
        default:
            navigate(back: false, targetApp: targetApp, method: navigationMethod)
        }
    }

    /// A posted keystroke goes to the frontmost window, so the method is chosen
    /// for that app. Activating anything first would steal focus.
    func navigate(
        back: Bool,
        targetApp: String?,
        method override: NavigationMethod?
    ) {
        let app = targetApp ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let method = override ?? NavigationMethod(targetApp: app)
        lastNavigation = "\(back ? "Back" : "Forward") to \(app) by \(method.title)"
        deliverNavigation(method, back: back)
    }

    func deliverNavigation(_ method: NavigationMethod, back: Bool) {
        switch method {
        case .swipe:
            NavigationSwipe.post(back ? .left : .right)
        case .mouseButton:
            click(
                CGMouseButton(rawValue: back ? 3 : 4) ?? .center,
                clicks: 1,
                tap: .cgSessionEventTap
            )
        case .commandBracket:
            press(key: back ? 33 : 30, flags: .maskCommand)
        case .optionCommandBracket:
            press(key: back ? 33 : 30, flags: [.maskCommand, .maskAlternate])
        case .commandArrow:
            press(key: back ? 123 : 124, flags: .maskCommand)
        }
    }

    /// A zero-length press gives a pressed state no frame to draw in.
    func click(
        _ button: CGMouseButton,
        clicks: Int64,
        tap: CGEventTapLocation = .cghidEventTap
    ) {
        let at = CGEvent(source: nil)?.location ?? .zero
        let events = InputEventFactory.mouseClick(button: button, location: at, clicks: clicks)

        for (step, event) in events.enumerated() {
            guard step > 0 else {
                send(event, tap: tap)
                continue
            }
            let delay = Double(step) * Self.clickHold
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                MainActor.assumeIsolated { self?.send(event, tap: tap) }
            }
        }
    }

    /// The trailing bare event clears modifier state, or the system can believe
    /// modifiers are still held and fire the wrong hotkey.
    func post(_ combo: KeyCombo) {
        press(key: CGKeyCode(combo.keyCode), flags: combo.flags)
        send(CGEvent(source: nil), tap: .cgSessionEventTap)
    }

    func post(_ hotKey: SymbolicHotKey) {
        guard let shortcut = hotKey.shortcut else { return }
        press(key: shortcut.key, flags: shortcut.flags)
        send(CGEvent(source: nil), tap: .cgSessionEventTap)
    }

    func press(key: CGKeyCode, flags: CGEventFlags = []) {
        for isDown in [true, false] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: isDown)
            event?.flags = flags
            send(event, tap: .cgSessionEventTap)
        }
    }

    func send(_ event: CGEvent?, tap: CGEventTapLocation = .cghidEventTap) {
        event?.setIntegerValueField(.eventSourceUserData, value: EventSignature.value)
        event?.post(tap: tap)
    }
}

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

        // An open menu spins a nested run loop that starves a default-mode timer.
        let ticker = Timer(timeInterval: Glide.tick, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advance() }
        }
        RunLoop.main.add(ticker, forMode: .common)
        timer = ticker

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
