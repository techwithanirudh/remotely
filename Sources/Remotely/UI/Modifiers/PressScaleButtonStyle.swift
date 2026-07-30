import SwiftUI

struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled && !reduceMotion

        configuration.label
            .scaleEffect(pressed ? Theme.Motion.pressScale : 1)
            .animation(
                pressed ? Theme.Motion.pressIn : Theme.Motion.pressOut,
                value: pressed
            )
    }
}

extension ButtonStyle where Self == PressScaleButtonStyle {
    static var pressScale: PressScaleButtonStyle { PressScaleButtonStyle() }
}
