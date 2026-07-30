import RemoteKit
import SwiftUI

struct AboutSettingsPane: View {
    @ObservedObject var bridge: RemoteBridge

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        SettingsPane(page: .about) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    HStack(alignment: .top, spacing: 12) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Remote Bridge").font(.system(size: 15, weight: .semibold))
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
                    .padding(Theme.Card.inset)
                }

                Spacer().frame(height: 14)

                Card {
                    Row(title: "Display") {
                        Text(bridge.displayName ?? "Not detected yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    HairlineDivider()
                    Row(
                        title: "Onboarding",
                        subtitle: "Walk through connecting and practising again."
                    ) {
                        Button("Replay") { AppCoordinator.shared?.replayOnboarding() }
                            .controlSize(.small)
                    }
                }
            }
        }
    }
}
