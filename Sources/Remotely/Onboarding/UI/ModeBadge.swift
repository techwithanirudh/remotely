import RemotelyKit
import SwiftUI

struct ModeBadge: View {
    let isScrolling: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isScrolling
                ? RemoteAction.toggleScrolling.symbol
                : RemoteAction.moveUp.symbol)
                .font(.system(size: 10, weight: .semibold))

            Text(isScrolling ? "Scrolling" : "Moving the pointer")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(isScrolling ? Color.accentColor : .secondary)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            (isScrolling ? Color.accentColor : .primary)
                .opacity(isScrolling ? Theme.Opacity.tint : Theme.Opacity.tintSoft),
            in: Capsule()
        )
        .animation(Theme.Motion.state, value: isScrolling)
    }
}
