import SwiftUI

struct Row<Control: View>: View {
    let title: String
    var subtitle: String?
    var symbol: String?
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: Theme.Space.icon) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: Theme.Card.glyphWidth)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13))

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 12)
            control
        }
        .padding(.horizontal, Theme.Card.inset)
        .padding(.vertical, 9)
        .frame(minHeight: subtitle == nil ? Theme.Card.rowHeight : 56)
    }
}
