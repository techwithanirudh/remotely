import SwiftUI

struct StatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundStyle(tint)
        }
        .padding(.horizontal, 9)
        .frame(height: 23)
        .background(tint.opacity(Theme.tintWash), in: Capsule())
    }
}
