import CoreGraphics
import Foundation
import RemoteKit

func bindingsTests() {
    Expect.suite("Bindings") {
        Expect.that(Bindings.standard.customized.byButton.isEmpty,
                    "untouched bindings persist nothing")

        var bindings = Bindings.standard
        bindings[.up] = ButtonBinding(.moveLeft)
        Expect.equal(Array(bindings.customized.byButton.keys), [.up],
                     "only changed buttons are persisted")

        let resolved = Bindings.resolving(bindings.customized)
        Expect.equal(
            resolved[.up],
            ButtonBinding(.moveLeft),
            "a customized button survives a round trip"
        )
        Expect.equal(resolved[.back], Bindings.standard[.back],
                     "changing a default still reaches someone who customized a different button")

        Expect.that(!ButtonBinding(.keyboardShortcut).isComplete,
                    "a shortcut binding is incomplete until something is recorded")
        Expect.that(
            ButtonBinding(.keyboardShortcut, combo: KeyCombo(keyCode: 13, modifiers: .maskCommand))
                .isComplete,
            "a shortcut binding with a combination is complete"
        )
        Expect.that(ButtonBinding(.leftClick).isComplete, "a plain action needs no payload")

        do {
            var withCombo = Bindings.standard
            withCombo[.back] = ButtonBinding(.keyboardShortcut,
                                             combo: KeyCombo(
                                                 keyCode: 13,
                                                 modifiers: [.maskCommand, .maskShift]
                                             ))
            let roundTripped = (try? JSONEncoder().encode(withCombo.customized))
                .flatMap { try? JSONDecoder().decode(Bindings.self, from: $0) }
            Expect.equal(roundTripped.map { Bindings.resolving($0)[.back] }, withCombo[.back],
                         "bindings round-trip through Codable")
        }
    }
}
