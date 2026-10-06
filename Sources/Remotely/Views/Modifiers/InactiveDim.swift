import SwiftUI

struct InactiveDim: ViewModifier {
    @Environment(\.controlActiveState) private var activeState

    func body(content: Content) -> some View {
        content.opacity(activeState == .inactive ? Theme.Opacity.inactive : 1)
    }
}

extension View {
    func dimsWhenInactive() -> some View {
        modifier(InactiveDim())
    }
}
