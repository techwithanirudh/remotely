import LaunchAtLogin
import RemoteKit
import SwiftUI

struct GeneralSettingsPane: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        SettingsPane(page: .general) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    Row(title: "Enable remote bridge") {
                        Toggle("", isOn: $bridge.isEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    HairlineDivider()
                    Row(title: "Launch at login") {
                        LaunchAtLogin.Toggle("")
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }

                SectionLabel(title: "Permissions")

                Card {
                    Row(
                        title: "Accessibility",
                        subtitle: bridge.hasAccessibility
                            ? "Pointer and keyboard control is allowed."
                            : "Required to move the pointer and press keys."
                    ) {
                        if bridge.hasAccessibility {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Button("Grant Access") { bridge.requestPermission() }
                                .controlSize(.small)
                        }
                    }
                }

                SectionLabel(title: "Pointer")

                Card {
                    Row(
                        title: "Pointer speed",
                        subtitle: "How fast the pointer moves while you hold an arrow."
                    ) {
                        HStack(spacing: 9) {
                            Slider(value: $bridge.sensitivity, in: 0.4 ... 2, step: 0.1)
                                .frame(width: 118)
                            Text(String(format: "%.1f×", bridge.sensitivity))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 42, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}
