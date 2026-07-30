import RemoteKit
import SwiftUI

struct ControlsSettingsPane: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        SettingsPane(page: .controls) {
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
                        subtitle: "Nudges the pointer a few pixels, for hitting a small target."
                    )
                    HairlineDivider()
                    InfoRow(
                        symbol: "hand.point.up.left.and.text",
                        title: "Hold an arrow",
                        subtitle: "Glides the pointer, speeding up the longer you hold."
                    )
                    HairlineDivider()
                    InfoRow(
                        symbol: RemoteAction.leftClick.symbol,
                        title: "Press Center",
                        subtitle: "Clicks. Press twice to double-click, hold for a right click."
                    )
                    HairlineDivider()
                    InfoRow(
                        symbol: RemoteAction.toggleScrolling.symbol,
                        title: "Press Back twice",
                        subtitle: "Switches the arrows between moving the pointer and scrolling."
                    )
                }

                SectionLabel(title: "Pointer")
                Card { bindingRows([.up, .down, .left, .right]) }

                SectionLabel(title: "Center")
                Card { bindingRows([.center, .centerDouble, .centerHold]) }

                SectionLabel(title: "Back")
                Card { bindingRows([.back, .backDouble, .backHold]) }

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

    private func bindingRows(_ buttons: [RemoteButton]) -> some View {
        ForEach(Array(buttons.enumerated()), id: \.element) { index, button in
            if index > 0 { HairlineDivider() }
            BindingRow(button: button, bridge: bridge)
        }
    }
}
