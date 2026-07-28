import RemoteKit
import SwiftUI

struct DiagnosticsPage: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        PageShell(page: .diagnostics) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    Row(title: "Remote signal") {
                        StatusBadge(
                            text: bridge.status.isReady ? "Receiving" : "None yet",
                            tint: bridge.status.isReady ? .green : .orange
                        )
                    }
                    Divider1px()
                    Row(title: "Accessibility") {
                        StatusBadge(
                            text: bridge.hasAccessibility ? "Allowed" : "Required",
                            tint: bridge.hasAccessibility ? .green : .orange
                        )
                    }
                    Divider1px()
                    Row(title: "Last button") {
                        Text(bridge.lastKey?.title ?? "None")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                SectionLabel(title: "Events")
                EventLog(bridge: bridge)
            }
        }
    }
}

private struct EventLog: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(bridge.log.count) events")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") { bridge.clearLog() }
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(bridge.logText(), forType: .string)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 12)
            .frame(height: 34)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if bridge.log.isEmpty {
                        Text("Remote events will appear here.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 44)
                    } else {
                        ForEach(bridge.log.suffix(100)) { entry in
                            HStack(alignment: .firstTextBaseline, spacing: 9) {
                                Text(entry.time)
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
        .card()
    }
}
