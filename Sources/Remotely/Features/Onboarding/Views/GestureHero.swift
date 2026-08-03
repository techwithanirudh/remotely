import SwiftUI

struct GestureHero: View {
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(Theme.Opacity.tintSoft))
                .frame(width: 132, height: 132)

            Circle()
                .fill(tint.opacity(Theme.Opacity.tint))
                .frame(width: 96, height: 96)

            Image(systemName: symbol)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(height: 132)
    }
}
