import AppKit
import ApplicationServices
import Carbon.HIToolbox
import RemoteCore

@MainActor
final class MacController {
    private var lastMoveAt = Date.distantPast
    private var repeatedMoves = 0

    /// Pointer glide state. Presses arrive as discrete CEC repeats, so each one
    /// retargets a spring that the timer chases — otherwise the cursor teleports.
    private var glideTarget: CGPoint?
    private var glideTimer: Timer?

    func requestAccessibilityPermission() -> Bool {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func perform(
        _ action: MacAction,
        cursorStep: CGFloat = 42
    ) {
        switch action {
        case .none: break
        case .moveUp: moveCursor(dx: 0, dy: -1, baseStep: cursorStep)
        case .moveDown: moveCursor(dx: 0, dy: 1, baseStep: cursorStep)
        case .moveLeft: moveCursor(dx: -1, dy: 0, baseStep: cursorStep)
        case .moveRight: moveCursor(dx: 1, dy: 0, baseStep: cursorStep)
        case .leftClick: click(button: .left, clickState: 1)
        case .doubleClick: click(button: .left, clickState: 2)
        case .rightClick: click(button: .right, clickState: 1)
        case .browserBack: pressKey(33, flags: .maskCommand) // Command-[
        case .showDesktop: pressKey(103) // F11
        case .missionControl: pressKey(126, flags: .maskControl) // Control-Up
        }
    }

    private func moveCursor(dx: CGFloat, dy: CGFloat, baseStep: CGFloat) {
        let now = Date()
        if now.timeIntervalSince(lastMoveAt) < 0.38 {
            repeatedMoves = min(repeatedMoves + 1, 8)
        } else {
            repeatedMoves = 0
        }
        lastMoveAt = now

        let step = baseStep + CGFloat(repeatedMoves) * max(8, baseStep * 0.28)
        let origin = glideTarget ?? CGEvent(source: nil)?.location ?? .zero
        glideTarget = CGPoint(
            x: max(0, min(CGFloat(CGDisplayPixelsWide(CGMainDisplayID())) - 1, origin.x + dx * step)),
            y: max(0, min(CGFloat(CGDisplayPixelsHigh(CGMainDisplayID())) - 1, origin.y + dy * step))
        )
        startGlide()
    }

    private func startGlide() {
        guard glideTimer == nil else { return }
        glideTimer = .scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.stepGlide() }
        }
    }

    private func stepGlide() {
        guard let target = glideTarget else { return endGlide() }
        let current = CGEvent(source: nil)?.location ?? target
        let delta = CGPoint(x: target.x - current.x, y: target.y - current.y)

        guard abs(delta.x) >= 0.6 || abs(delta.y) >= 0.6 else {
            warp(to: target)
            return endGlide()
        }
        warp(to: CGPoint(x: current.x + delta.x * 0.32, y: current.y + delta.y * 0.32))
    }

    private func endGlide() {
        glideTimer?.invalidate()
        glideTimer = nil
        glideTarget = nil
    }

    private func warp(to point: CGPoint) {
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
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
            event?.post(tap: .cghidEventTap)
        }
    }

    private func pressKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

}
