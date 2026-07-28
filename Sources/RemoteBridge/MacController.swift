import AppKit
import ApplicationServices
import Carbon.HIToolbox
import RemoteCore

@MainActor
final class MacController {
    private var lastMoveAt = Date.distantPast
    private var repeatedMoves = 0

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
        case .leftClick: click()
        case .browserBack: pressKey(33, flags: .maskCommand) // Command-[
        case .showDesktop: pressKey(103) // F11 / Show Desktop (macOS default)
        case .playPause: mediaKey(NX_KEYTYPE_PLAY)
        case .rewind: mediaKey(NX_KEYTYPE_REWIND)
        case .fastForward: mediaKey(NX_KEYTYPE_FAST)
        case .volumeUp: mediaKey(NX_KEYTYPE_SOUND_UP)
        case .volumeDown: mediaKey(NX_KEYTYPE_SOUND_DOWN)
        case .mute: mediaKey(NX_KEYTYPE_MUTE)
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
        let current = NSEvent.mouseLocation
        guard let mainHeight = NSScreen.screens.first?.frame.height else { return }
        let quartzCurrent = CGPoint(x: current.x, y: mainHeight - current.y)
        let target = CGPoint(
            x: max(0, min(CGFloat(CGDisplayPixelsWide(CGMainDisplayID())) - 1, quartzCurrent.x + dx * step)),
            y: max(0, min(CGFloat(CGDisplayPixelsHigh(CGMainDisplayID())) - 1, quartzCurrent.y + dy * step))
        )
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private func click() {
        let point = CGEvent(source: nil)?.location ?? .zero
        CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
        CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private func pressKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

    private func mediaKey(_ key: Int32) {
        for (isDown, state) in [(true, 0xA), (false, 0xB)] {
            let data1 = Int((key << 16) | Int32(state << 8))
            let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: isDown ? .init(rawValue: 0xA00) : .init(rawValue: 0xB00),
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            event?.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}
