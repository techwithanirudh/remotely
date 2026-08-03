import SwiftUI

struct Pill: View {
    let title: String
    var tint: Color = .accentColor

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(tint.opacity(Theme.Opacity.tint), in: Capsule())
    }
}
