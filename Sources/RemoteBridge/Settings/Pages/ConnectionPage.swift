import SwiftUI
import RemoteCore

struct ConnectionSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .connection) {
            VStack(alignment: .leading, spacing: 0) {
                ConnectionHero(model: model)

                SectionLabel(title: "Setup")

                SettingsCard {
                    ChecklistRow(
                        title: "Connect this Mac to your TV with an HDMI cable",
                        complete: model.connectionState == .running
                    )
                    CardDivider()
                    ChecklistRow(
                        title: "Switch the TV to that HDMI input",
                        complete: model.connectionState == .running
                    )
                    CardDivider()
                    ChecklistRow(
                        title: "Turn on HDMI-CEC in the TV's settings",
                        complete: model.connectionState == .running
                    )
                }

                Label(
                    "TV makers rename HDMI-CEC: Samsung calls it Anynet+, LG SimpLink, "
                        + "Sony Bravia Sync, Philips EasyLink.",
                    systemImage: "info.circle"
                )
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.top, 10)
            }
        }
    }
}

struct ConnectionHero: View {
    @ObservedObject var model: BridgeModel

    private var tint: Color {
        switch model.status {
        case .ready: .green
        case .waitingForRemote, .needsPermission: .orange
        case .paused: .gray
        case .unsupported, .failed: .red
        }
    }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: model.status.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(model.status.title)
                    .font(.system(size: 14, weight: .semibold))
                Text(model.status.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if model.status == .needsPermission {
                Button("Allow…") { model.requestAccessibility() }
                    .controlSize(.small)
            } else {
                Button("Reconnect") { model.reconnect() }
                    .controlSize(.small)
            }
        }
        .padding(14)
        .cardSurface()
    }
}

struct ChecklistRow: View {
    let title: String
    let complete: Bool

    var body: some View {
        HStack {
            Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(complete ? .green : .secondary)
            Text(title).font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }
}
