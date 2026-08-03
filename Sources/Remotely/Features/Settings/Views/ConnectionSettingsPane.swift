import ComposableArchitecture
import Defaults
import RemotelyKit
import SwiftUI

struct ConnectionSettingsPane: View {
    let remote: StoreOf<RemoteFeature>
    @Default(.tvBrand) private var brand

    private var isLinked: Bool { remote.status.isReady }

    var body: some View {
        SettingsPane(page: .connection) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    HStack(spacing: 13) {
                        Image(systemName: remote.status.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(remote.status.tint)
                            .frame(width: 34, height: 34)
                            .background(
                                remote.status.tint.opacity(Theme.Opacity.tint),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(remote.status.title).font(.system(size: 14, weight: .semibold))
                            Text(remote.status.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        if remote.status == .needsPermission {
                            Button("Allow…") { remote.send(.requestPermission) }.controlSize(.small)
                        } else {
                            Button("Reconnect") { remote.send(.reconnect) }.controlSize(.small)
                        }
                    }
                    .padding(Theme.Card.inset)
                }

                SectionLabel(title: "Setup")

                Card {
                    Checklist(
                        title: "Connect this Mac to your display with an HDMI cable",
                        isDone: isLinked
                    )
                    HairlineDivider()
                    Checklist(title: "Switch the display to that HDMI input", isDone: isLinked)
                    HairlineDivider()
                    Checklist(title: "Turn on HDMI-CEC in the display's settings", isDone: isLinked)
                }

                SectionLabel(title: "Where to find it")

                Card { BrandGuide(brand: $brand) }
            }
        }
    }
}
