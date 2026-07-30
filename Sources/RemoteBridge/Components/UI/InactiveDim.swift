import SwiftUI

/// Fades a view once the window is not in front. Applied to icons and labels
/// rather than to whole rows, so a selected row keeps its background at full
/// strength the way Alcove's does.
extension View {
    func dimsWhenInactive() -> some View { modifier(InactiveDim()) }
}

private struct InactiveDim: ViewModifier {
    @Environment(\.controlActiveState) private var activeState

    func body(content: Content) -> some View {
        content.opacity(activeState == .inactive ? Theme.inactiveDim : 1)
    }
}
