import SwiftUI

struct DoneLine: View {
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
        }
        .padding(.horizontal, Theme.Card.inset)
        .frame(height: 30)
        .card(radius: Theme.Control.radius)
    }
}
