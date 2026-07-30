import CoreGraphics
import RemotelyKit

func keyCombinationsTests() {
    Expect.suite("Key combinations") {
        Expect.equal(KeyCombo(keyCode: 13, modifiers: [.maskCommand, .maskNonCoalesced]).flags,
                     .maskCommand,
                     "only the modifiers worth storing are kept")
        Expect.equal(
            KeyCombo(keyCode: 53, modifiers: [.maskCommand, .maskControl, .maskShift]).display,
            "⌃⇧⌘⎋",
            "modifiers print in the order macOS uses"
        )
        Expect.equal(KeyCombo(keyCode: 36, modifiers: []).display, "↩", "Return is named")
        Expect.equal(KeyCombo(keyCode: 49, modifiers: []).display, "Space", "Space is named")
        Expect.equal(KeyCombo(keyCode: 126, modifiers: []).display, "↑", "Arrow keys are named")
    }
}
