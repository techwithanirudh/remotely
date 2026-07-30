import SwiftUI

/// A tinted rounded-square icon, as used in the sidebar and page headers.
struct IconTile: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.53, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                tint.gradient,
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
    }
}
