import RemoteKit
import SwiftUI

struct AboutPage: View {
    @ObservedObject var bridge: RemoteBridge

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        PageShell(page: .about) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    // Title, version and blurb share one left edge; hanging the
                    // blurb under the icon left it out of line with both.
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
                    .padding(Theme.cardPadding)
                }

                Spacer().frame(height: 14)

                Card {
                    Row(title: "Display") {
                        Text(bridge.displayName ?? "Not detected yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Divider1px()
                    Row(
                        title: "Onboarding",
                        subtitle: "Walk through connecting and practising again."
                    ) {
                        Button("Replay") { AppCoordinator.shared?.replayOnboarding() }
                            .controlSize(.small)
                    }
                }

                Text("Remote buttons arrive through CoreRC, a private part of macOS. "
                     + "A system update could change how it behaves.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 9)
                    .padding(.top, 12)
            }
        }
    }
}
