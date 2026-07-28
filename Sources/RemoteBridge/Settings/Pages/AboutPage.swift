import SwiftUI
import RemoteCore

struct AboutSettingsView: View {
    @ObservedObject var model: BridgeModel

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3"
    }

    var body: some View {
        PageShell(page: .about) {
            VStack(alignment: .leading, spacing: 0) {
                // Title, version and blurb share one left edge; hanging the
                // blurb under the icon instead left it out of line with both.
                SettingsCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "av.remote.fill")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Remote Bridge")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Version \(version)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("Turns your TV remote into a pointer for this Mac, "
                             + "over the HDMI cable you already have.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 0)
                }
                .padding(Theme.cardPadding)
                }

                SectionLabel(title: "Connection")

                SettingsCard {
                    SettingRow(title: "Display") {
                        Text(model.displayName ?? "Not detected yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    CardDivider()
                    SettingRow(
                        title: "Onboarding",
                        subtitle: "Walk through connecting and practising again."
                    ) {
                        Button("Replay") {
                            (NSApp.delegate as? AppDelegate)?.replayOnboarding()
                        }
                        .controlSize(.small)
                    }
                }

                Text("Remote buttons arrive through CoreRC, a private part of macOS. "
                     + "A system update could change how it behaves.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
            }
        }
    }
}
