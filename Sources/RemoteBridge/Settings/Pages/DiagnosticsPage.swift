import SwiftUI
import RemoteCore

struct DiagnosticsSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .diagnostics) {
            VStack(alignment: .leading, spacing: 0) {
                LiveActivityCard(model: model)

                SectionLabel(title: "System Status")

                SettingsCard {
                    SettingRow(title: "Remote signal") {
                        StatusBadge(
                            text: model.connectionState == .running ? "Receiving" : "None yet",
                            color: model.connectionState == .running ? .green : .orange
                        )
                    }
                    CardDivider()
                    SettingRow(title: "Accessibility") {
                        StatusBadge(
                            text: model.accessibilityGranted ? "Allowed" : "Required",
                            color: model.accessibilityGranted ? .green : .orange
                        )
                    }
                }

                SectionLabel(title: "Events")

                VStack(spacing: 0) {
                    HStack {
                        Text("\(model.logs.count) events")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") { model.clearLogs() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .semibold))
                        Button("Copy") { model.copyLogs() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 34)

                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            if model.logs.isEmpty {
                                Text("CEC events will appear here.")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 44)
                            } else {
                                ForEach(model.logs.suffix(100)) { entry in
                                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                                        Text(entry.timestamp)
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 72, alignment: .leading)
                                        Text(entry.message)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    .font(.system(size: 10, design: .monospaced))
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 190)
                }
                .background(Theme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.cardStroke)
                }
            }
        }
    }
}

/// Shows the most recent button and what it did. Replaces the old mock remote —
/// any CEC display can be paired here, so we cannot draw a specific handset.

struct LiveActivityCard: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        SettingsCard {
            HStack(spacing: 14) {
                SymbolTile(
                    symbol: model.lastButton?.symbol ?? "dot.radiowaves.left.and.right",
                    tint: model.lastButton == nil ? .gray : .accentColor,
                    size: 38
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.lastButton?.title ?? "Waiting for a button")
                        .font(.system(size: 14, weight: .semibold))

                    if let button = model.lastButton {
                        Text(model.action(for: button).title)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Press any button on your TV remote.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(model.buttonEventCount)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("events")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .animation(.snappy(duration: 0.22), value: model.buttonEventCount)
        }
        .padding(.top, 14)
    }
}
