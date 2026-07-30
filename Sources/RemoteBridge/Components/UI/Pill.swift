import SwiftUI

struct Pill: View {
    let text: String
    var tint: Color = .accentColor

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(tint.opacity(Theme.tintWash), in: Capsule())
    }
}
