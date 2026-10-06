import SwiftUI

struct Checklist: View {
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: Theme.Space.icon) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(isDone ? .green : .secondary)
            Text(title).font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, Theme.Card.inset)
        .frame(height: Theme.Card.rowHeight)
    }
}
