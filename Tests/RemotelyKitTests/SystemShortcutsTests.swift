import CoreGraphics
import RemotelyKit

func systemShortcutsTests() {
    Expect.suite("System shortcuts") {
        // Show Desktop and Mission Control were posted as bare F11 and control-Up,
        // which the window server matches against nothing: both of its bindings
        // carry the fn bit. Anything read back has to bring its modifiers with it.
        for hotKey in [SymbolicHotKey.showDesktop, .missionControl] {
            guard let shortcut = hotKey.shortcut else { continue }

            Expect.that(
                shortcut.flags.contains(.maskSecondaryFn),
                "\(hotKey) keeps the fn modifier its binding is registered with"
            )
            Expect.that(
                shortcut.key != CGKeyCode.max,
                "\(hotKey) resolves to a real key"
            )
        }
    }
}
