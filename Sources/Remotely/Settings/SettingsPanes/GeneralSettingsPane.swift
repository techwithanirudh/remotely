import LaunchAtLogin
import RemotelyKit
import SwiftUI

struct GeneralSettingsPane: View {
    @ObservedObject var remote: Remote

    var body: some View {
        SettingsPane(page: .general) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    Row(title: "Enable remote remote") {
                        Toggle("", isOn: $remote.isEnabled)
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
                        subtitle: remote.hasAccessibility
                            ? "Pointer and keyboard control is allowed."
                            : "Required to move the pointer and press keys."
                    ) {
                        if remote.hasAccessibility {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Button("Grant Access") { remote.requestPermission() }
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
                            Slider(value: $remote.sensitivity, in: 0.4 ... 2, step: 0.1)
                                .frame(width: 118)
                            Text(String(format: "%.1f×", remote.sensitivity))
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
