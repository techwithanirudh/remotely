import Defaults
import RemotelyKit
import SwiftUI

struct AboutSettingsPane: View {
    @State private var confirmingReset = false
    @Default(.wantsBetaUpdates) private var betaUpdates

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        SettingsPane(page: .about) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    HStack(alignment: .top, spacing: 12) {
                        AppIconButton(size: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Remotely").font(.system(size: 15, weight: .semibold))
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
                    Row(
                        title: "Updates",
                        subtitle: betaUpdates
                            ? "Including beta releases."
                            : "Stable releases only."
                    ) {
                        HStack(spacing: 8) {
                            Toggle("Beta", isOn: $betaUpdates)
                                .toggleStyle(.checkbox)
                                .controlSize(.small)
                            Button("Check Now") {
                                AppCoordinator.shared?.checkForUpdates()
                            }
                            .controlSize(.small)
                        }
                    }
                    HairlineDivider()
                    Row(
                        title: "Onboarding",
                        subtitle: "Walk through connecting and practising again."
                    ) {
                        Button("Replay") { AppCoordinator.shared?.replayOnboarding() }
                            .controlSize(.small)
                    }
                    HairlineDivider()
                    Row(
                        title: "Reset Remotely",
                        subtitle: "Clear every preference and restart onboarding."
                    ) {
                        Button("Reset…", role: .destructive) { confirmingReset = true }
                            .controlSize(.small)
                    }
                }
            }
        }
        .confirmationDialog(
            "Reset Remotely?",
            isPresented: $confirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                AppCoordinator.shared?.factoryReset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your controls, sensitivity, TV choice, and onboarding progress.")
        }
    }
}
