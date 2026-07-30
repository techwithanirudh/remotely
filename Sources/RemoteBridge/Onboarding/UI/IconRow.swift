import SwiftUI

struct IconRow: View {
    struct Item: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
        let label: String
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(Theme.Color.divider).frame(width: 1, height: 46)
                }

                VStack(spacing: 7) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(item.tint)
                        .frame(height: 22)

                    Text(item.label)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 13)
        .card()
    }
}
