import RemoteKit
import SwiftUI

struct ControlsPage: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        PageShell(page: .controls) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    Row(
                        title: "Make the remote yours",
                        subtitle: "Assign any macOS action to each remote button."
                    ) {
                        Button("Reset Defaults") { bridge.resetAllBindings() }
                            .controlSize(.small)
                    }
                }

                SectionLabel(title: "How to use the remote")

                Card {
                    InfoRow(
                        symbol: "hand.tap",
                        title: "Tap an arrow",
                        detail: "Nudges the pointer a few pixels, for hitting a small target."
                    )
                    Divider1px()
                    InfoRow(
                        symbol: "hand.point.up.left.and.text",
                        title: "Hold an arrow",
                        detail: "Glides the pointer, speeding up the longer you hold."
                    )
                    Divider1px()
                    InfoRow(
                        symbol: "cursorarrow.click",
                        title: "Press Center",
                        detail: "Clicks. Press twice to double-click, hold for a right click."
                    )
                    Divider1px()
                    InfoRow(
                        symbol: "arrow.up.and.down.text.horizontal",
                        title: "Press Back twice",
                        detail: "Switches the arrows between moving the pointer and scrolling.",
                        tint: bridge.isScrolling ? .accentColor : .secondary,
                        badge: bridge.isScrolling ? "Scrolling" : nil
                    )
                }

                SectionLabel(title: "Pointer")
                Card { bindingRows([.up, .down, .left, .right]) }

                SectionLabel(title: "Center")
                Card { bindingRows([.center, .centerDouble, .centerHold]) }

                SectionLabel(title: "Back")
                Card { bindingRows([.back, .backDouble]) }

                Label(
                    "Volume, media and Home never reach the Mac. Displays handle those "
                        + "themselves and keep them off the CEC bus.",
                    systemImage: "info.circle"
                )
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 9)
                .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private func bindingRows(_ buttons: [RemoteButton]) -> some View {
        ForEach(Array(buttons.enumerated()), id: \.element) { index, button in
            if index > 0 { Divider1px() }
            BindingRow(button: button, bridge: bridge)
        }
    }
}

private struct BindingRow: View {
    let button: RemoteButton
    @ObservedObject var bridge: RemoteBridge

    private var binding: ButtonBinding { bridge.binding(for: button) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: button.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: 22)

            Text(button.shortTitle).font(.system(size: 13))

            Spacer(minLength: 8)

            // Reset sits before the picker in a slot that is always reserved,
            // so the pickers stay on one line whether or not it is showing.
            Button { bridge.resetBinding(for: button) } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reset to default")
            .opacity(bridge.isStandard(button) ? 0 : 1)
            .disabled(bridge.isStandard(button))
            .frame(width: 14)

            ActionMenu(
                binding: binding,
                onPick: { bridge.setAction($0, for: button) },
                onRecord: { bridge.setCombo($0, for: button) }
            )
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(minHeight: 43)
    }
}
