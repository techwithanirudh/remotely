import Defaults
import RemoteKit
import SwiftUI

struct ConnectionSettingsPane: View {
    @ObservedObject var bridge: RemoteBridge
    @Default(.tvBrand) private var brand

    private var isLinked: Bool { bridge.status.isReady }

    var body: some View {
        SettingsPane(page: .connection) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    HStack(spacing: 13) {
                        Image(systemName: bridge.status.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(bridge.status.tint)
                            .frame(width: 34, height: 34)
                            .background(
                                bridge.status.tint.opacity(Theme.Opacity.tint),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bridge.status.title).font(.system(size: 14, weight: .semibold))
                            Text(bridge.status.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        if bridge.status == .needsPermission {
                            Button("Allow…") { bridge.requestPermission() }.controlSize(.small)
                        } else {
                            Button("Reconnect") { bridge.reconnect() }.controlSize(.small)
                        }
                    }
                    .padding(Theme.Card.inset)
                }

                SectionLabel(title: "Setup")

                Card {
                    Checklist(
                        title: "Connect this Mac to your TV with an HDMI cable",
                        isDone: isLinked
                    )
                    HairlineDivider()
                    Checklist(title: "Switch the TV to that HDMI input", isDone: isLinked)
                    HairlineDivider()
                    Checklist(title: "Turn on HDMI-CEC in the TV's settings", isDone: isLinked)
                }

                SectionLabel(title: "Where to find it")

                Card { BrandGuide(brand: $brand) }
            }
        }
    }
}
