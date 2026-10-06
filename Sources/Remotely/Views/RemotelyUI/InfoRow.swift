import SwiftUI

struct InfoRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    var tint: Color = .secondary
    var badge: String?

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.icon) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: Theme.Card.glyphWidth, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    if let badge { Pill(title: badge) }
                    Spacer(minLength: 0)
                }

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Theme.Card.inset)
        .padding(.vertical, 11)
        .frame(minHeight: 50)
    }
}
