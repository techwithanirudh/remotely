import RemotelyKit
import SwiftUI

struct BindingRow: View {
    let button: RemoteButton
    @ObservedObject var remote: Remote

    private var binding: ButtonBinding { remote.binding(for: button) }

    var body: some View {
        HStack(spacing: Theme.Space.icon) {
            Image(systemName: button.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: Theme.Card.glyphWidth)

            Text(button.shortTitle).font(.system(size: 13))

            Spacer(minLength: 8)

            Button { remote.resetBinding(for: button) } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reset to default")
            .opacity(remote.isStandard(button) ? 0 : 1)
            .disabled(remote.isStandard(button))
            .frame(width: 14)

            ActionMenu(
                binding: binding,
                onPick: { remote.setAction($0, for: button) },
                onRecord: { remote.setCombo($0, for: button) }
            )
        }
        .padding(.horizontal, Theme.Card.inset)
        .frame(minHeight: Theme.Card.rowHeight)
    }
}
