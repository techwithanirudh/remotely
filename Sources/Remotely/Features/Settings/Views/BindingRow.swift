import ComposableArchitecture
import RemotelyKit
import SwiftUI

struct BindingRow: View {
    let button: RemoteButton
    let remote: StoreOf<RemoteFeature>

    private var binding: ButtonBinding { remote.bindings[button] }

    var body: some View {
        HStack(spacing: Theme.Space.icon) {
            Image(systemName: button.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: Theme.Card.glyphWidth)

            Text(button.shortTitle).font(.system(size: 13))

            Spacer(minLength: 8)

            Button { remote.send(.resetBinding(button)) } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reset to default")
            .opacity(remote.bindings.isStandard(button) ? 0 : 1)
            .disabled(remote.bindings.isStandard(button))
            .frame(width: 14)

            ActionMenu(
                binding: binding,
                onPick: { remote.send(.setAction($0, button)) },
                onRecord: { remote.send(.setCombo($0, button)) }
            )
        }
        .padding(.horizontal, Theme.Card.inset)
        .frame(minHeight: Theme.Card.rowHeight)
    }
}
