import CoreGraphics
import Foundation
import RemoteKit

// MARK: Gesture rules

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
        Expect.equal(reader.release(at: 0.05), [.triggerDeferred(.back, after: 0.38)],
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

// MARK: Bindings

Expect.suite("Bindings") {
    Expect.that(Bindings.standard.customised.byButton.isEmpty,
                "untouched bindings persist nothing")

    var bindings = Bindings.standard
    bindings[.up] = ButtonBinding(.moveLeft)
    Expect.equal(Array(bindings.customised.byButton.keys), [.up],
                 "only changed buttons are persisted")

    let resolved = Bindings.resolving(bindings.customised)
    Expect.equal(resolved[.up], ButtonBinding(.moveLeft), "a customised button survives a round trip")
    Expect.equal(resolved[.back], Bindings.standard[.back],
                 "changing a default still reaches someone who customised a different button")

    Expect.that(!ButtonBinding(.keyboardShortcut).isComplete,
                "a shortcut binding is incomplete until something is recorded")
    Expect.that(ButtonBinding(.keyboardShortcut, combo: KeyCombo(keyCode: 13, modifiers: .maskCommand)).isComplete,
                "a shortcut binding with a combination is complete")
    Expect.that(ButtonBinding(.leftClick).isComplete, "a plain action needs no payload")

    do {
        var withCombo = Bindings.standard
        withCombo[.back] = ButtonBinding(.keyboardShortcut,
                                   combo: KeyCombo(keyCode: 13, modifiers: [.maskCommand, .maskShift]))
        let data = try! JSONEncoder().encode(withCombo.customised)
        let decoded = try! JSONDecoder().decode(Bindings.self, from: data)
        Expect.equal(Bindings.resolving(decoded)[.back], withCombo[.back],
                     "bindings round-trip through Codable")
    }
}

// MARK: Key combinations

Expect.suite("Key combinations") {
    Expect.equal(KeyCombo(keyCode: 13, modifiers: [.maskCommand, .maskNonCoalesced]).flags,
                 .maskCommand,
                 "only the modifiers worth storing are kept")
    Expect.equal(KeyCombo(keyCode: 53, modifiers: [.maskCommand, .maskControl, .maskShift]).display,
                 "⌃⇧⌘⎋",
                 "modifiers print in the order macOS uses")
    Expect.equal(KeyCombo(keyCode: 36, modifiers: []).display, "↩", "Return is named")
    Expect.equal(KeyCombo(keyCode: 49, modifiers: []).display, "Space", "Space is named")
    Expect.equal(KeyCombo(keyCode: 126, modifiers: []).display, "↑", "Arrow keys are named")
}

// MARK: Glide curve

Expect.suite("Glide curve") {
    do {
        var glide = Glide.pointer(sensitivity: 1)
        let travelled = (0..<7).reduce(0.0) { total, _ in total + glide.advance() }
        Expect.that(travelled < 20, "a tap moves only a few points (\(Int(travelled)))")
    }

    do {
        var glide = Glide.pointer(sensitivity: 1)
        let first = glide.advance()
        for _ in 0..<60 { _ = glide.advance() }
        Expect.that(glide.advance() > first * 5, "holding ramps the speed up")
    }

    do {
        var glide = Glide.pointer(sensitivity: 1)
        for _ in 0..<1000 { _ = glide.advance() }
        Expect.that(glide.speed <= glide.maximumSpeed, "speed never exceeds its ceiling")
    }

    do {
        var slow = Glide.pointer(sensitivity: 0.5)
        var fast = Glide.pointer(sensitivity: 2)
        Expect.that(fast.advance() > slow.advance() * 3, "sensitivity scales the whole curve")
    }

    do {
        var pointer = Glide.pointer(sensitivity: 1)
        var scroll = Glide.scroll(sensitivity: 1)
        Expect.that(scroll.advance() < pointer.advance(), "scrolling is calmer than pointer motion")
    }
}

// MARK: Status

Expect.suite("Status") {
    Expect.equal(BridgeStatus(link: .listening, hasAccessibility: false), .needsPermission,
                 "a live link without permission is not ready")
    Expect.equal(BridgeStatus(link: .listening, hasAccessibility: true), .ready,
                 "a live link with permission is ready")
    Expect.equal(BridgeStatus(link: .waitingForDisplay, hasAccessibility: false), .needsPermission,
                 "permission is reported before the missing display")
    Expect.equal(BridgeStatus(link: .waitingForDisplay, hasAccessibility: true), .waitingForRemote,
                 "with permission granted the wait is on the display")
    Expect.equal(BridgeStatus(link: .stopped, hasAccessibility: true), .paused,
                 "being switched off reads as paused")
}

// MARK: Actions

Expect.suite("Actions") {
    Expect.equal(RemoteAction.moveUp.scrolling, .scrollUp, "moving maps to its scrolling counterpart")
    Expect.equal(RemoteAction.leftClick.scrolling, .leftClick, "a click is unaffected by scroll mode")
    Expect.that(RemoteAction.moveLeft.isContinuous, "movement is continuous")
    Expect.that(!RemoteAction.escape.isContinuous, "Escape is a one-shot")
    Expect.equal(RemoteAction.scrollDown.direction, CGVector(dx: 0, dy: 1), "down points down")
}

// MARK: CEC log parsing

Expect.suite("CEC log parsing") {
    let parser = CECLogParser()

    Expect.equal(
        parser.parse("2026-07-28 19:00:00.000 corercd RX: TV -> Playback Device 1: <User Control Pressed> 02"),
        .pressed(.down),
        "a pressed line decodes the wire code, not the English name"
    )
    Expect.equal(
        parser.parse("... <User Control Pressed> 00"), .pressed(.select), "0x00 is Select")
    Expect.equal(
        parser.parse("... <User Control Pressed> 0D"), .pressed(.back), "0x0D is Back")
    Expect.equal(
        parser.parse("... <User Control Released>"), .released,
        "a release carries no key code")
    Expect.that(
        parser.parse("... <User Control Pressed> 41") == nil,
        "an unmapped code is ignored rather than guessed at")
    Expect.that(parser.parse("unrelated daemon chatter") == nil, "unrelated lines are ignored")

    Expect.equal(
        parser.parse("CECBus <x> Link: Y; EDID: <CECEDIDAttributes: 0x600> Smart M70D vID: 0x4dd9"),
        .attached("Smart M70D"),
        "the display name is read out of the EDID line"
    )
    Expect.that(
        parser.parse("CECBus <x> Link: N; EDID: <CECEDIDAttributes: 0x600> Smart M70D vID: 0x1") == nil,
        "a down link is not reported as attached"
    )
}

exit(Expect.summarise())
