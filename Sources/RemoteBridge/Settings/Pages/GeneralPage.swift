import SwiftUI
import RemoteCore

struct GeneralSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .general) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsCard {
                    SettingRow(title: "Enable remote bridge") {
                        Toggle("", isOn: $model.bridgeEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    CardDivider()
                    SettingRow(title: "Launch at login") {
                        Toggle("", isOn: Binding(
                            get: { model.launchAtLoginEnabled },
                            set: { model.setLaunchAtLogin($0) }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                }

                SectionLabel(title: "Permissions")

                SettingsCard {
                    SettingRow(
                        title: "Accessibility",
                        subtitle: model.accessibilityGranted
                            ? "Pointer and keyboard control is allowed."
                            : "Required to move the pointer and send media keys."
                    ) {
                        if model.accessibilityGranted {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Button("Grant Access") {
                                model.requestAccessibility()
                            }
                            .controlSize(.small)
                        }
                    }
                }

                SectionLabel(title: "Pointer")

                SettingsCard {
                    SettingRow(
                        title: "Pointer speed",
                        subtitle: "How fast the pointer moves while you hold an arrow."
                    ) {
                        HStack(spacing: 9) {
                            Slider(value: $model.pointerSensitivity, in: 0.4...2.0, step: 0.1)
                                .frame(width: 118)
                            Text(String(format: "%.1f×", model.pointerSensitivity))
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
