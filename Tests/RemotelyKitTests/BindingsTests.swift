import CoreGraphics
import Foundation
import RemotelyKit

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
        Expect.equal(Bindings.standard[.backHold], ButtonBinding(.none),
                     "holding Back is unbound until Forward is known to work")

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

func bindingClashTests() {
    Expect.suite("Binding clashes") {
        Expect.that(
            RemoteButton.allCases.allSatisfy { Bindings.standard.clashes(with: $0).isEmpty },
            "the defaults never clash"
        )

        var clashing = Bindings.standard
        clashing[.backHold] = ButtonBinding(.leftClick)
        Expect.equal(clashing.clashes(with: .backHold), [.center],
                     "two buttons with the same action clash")
        Expect.equal(clashing.clashes(with: .center), [.backHold],
                     "a clash is reported from both sides")

        clashing[.centerDouble] = ButtonBinding(.none)
        clashing[.backHold] = ButtonBinding(.none)
        Expect.that(clashing.clashes(with: .backHold).isEmpty,
                    "Do Nothing on two buttons is not a clash")

        let save = KeyCombo(keyCode: 1, modifiers: .maskCommand)
        let quit = KeyCombo(keyCode: 12, modifiers: .maskCommand)
        clashing[.backHold] = ButtonBinding(.keyboardShortcut)
        clashing[.centerDouble] = ButtonBinding(.keyboardShortcut)
        Expect.that(clashing.clashes(with: .backHold).isEmpty,
                    "two unrecorded shortcuts do not clash")

        clashing[.backHold] = ButtonBinding(.keyboardShortcut, combo: save)
        clashing[.centerDouble] = ButtonBinding(.keyboardShortcut, combo: quit)
        Expect.that(clashing.clashes(with: .backHold).isEmpty,
                    "different shortcuts do not clash")

        clashing[.centerDouble] = ButtonBinding(.keyboardShortcut, combo: save)
        Expect.equal(clashing.clashes(with: .backHold), [.centerDouble],
                     "the same shortcut on two buttons clashes")
    }
}
