import SwiftUI
import RemoteCore

struct ConnectionSettingsView: View {
    @ObservedObject var model: BridgeModel
    @AppStorage(OnboardingProgress.brandKey) private var storedBrand = TVBrand.samsung.rawValue

    private var brand: Binding<TVBrand> {
        Binding(
            get: { TVBrand(rawValue: storedBrand) ?? .samsung },
            set: { storedBrand = $0.rawValue }
        )
    }

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

                SectionLabel(title: "Where to find it")

                SettingsCard {
                    BrandHelpRow(brand: brand)
                }
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


/// Brand picker, that maker's name for HDMI-CEC, the menu path, and a link out
/// to their own instructions. Naming only a few brands in a footnote left
/// everyone else guessing.
struct BrandHelpRow: View {
    @Binding var brand: TVBrand

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Text("My TV is a")
                    .font(.system(size: 13))

                Picker("", selection: $brand) {
                    ForEach(TVBrand.allCases) { Text($0.name).tag($0) }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 140)

                Spacer(minLength: 8)

                if let url = brand.supportURL {
                    Link(destination: url) {
                        Label("Instructions", systemImage: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Look for “\(brand.featureName)”")
                    .font(.system(size: 12, weight: .semibold))
                Text(brand.path)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
