import Defaults
import RemotelyKit
import SwiftUI

struct AboutSettingsPane: View {
    @State private var confirmingReset = false
    @ObservedObject private var updater = Updater.shared
    @Default(.releaseChannel) private var channel

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
                            Text("Turns your display's remote into a mouse.")
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
                    Button {
                        AppCoordinator.shared?.checkForUpdates()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Check for Updates…")
                                .font(.system(size: 13))
                            Spacer(minLength: 8)
                            Text(version)
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, Theme.Card.inset)
                        .frame(height: Theme.Card.rowHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    HairlineDivider()

                    Row(
                        title: "Automatically check for updates",
                        symbol: "arrow.triangle.2.circlepath"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { updater.checksAutomatically },
                            set: { updater.checksAutomatically = $0 }
                        ))
                        .labelsHidden()
                        .controlSize(.small)
                    }

                    HairlineDivider()

                    Row(
                        title: "Automatically install updates",
                        symbol: "square.and.arrow.down"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { updater.installsAutomatically },
                            set: { updater.installsAutomatically = $0 }
                        ))
                        .labelsHidden()
                        .controlSize(.small)
                    }

                    HairlineDivider()

                    Row(title: "Release channel", symbol: "flask") {
                        Picker("", selection: $channel) {
                            ForEach(ReleaseChannel.allCases) { Text($0.title).tag($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                        .controlSize(.small)
                    }
                }

                Spacer().frame(height: 14)

                Card {
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
            Text("This clears your controls, sensitivity, display choice, and onboarding progress.")
        }
    }
}
