import AppKit
import RemoteKit
import SwiftUI

struct EventLog: View {
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
            .padding(.horizontal, Theme.Card.inset)
            .frame(height: 34)

            HairlineDivider()

            if bridge.log.isEmpty {
                ZStack {
                    Text("Remote events will appear here.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .offset(y: -1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
            } else {
                ScrollView {
                    // The newest event must remain visible without following the scroll
                    // position.
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(bridge.log.suffix(100).reversed()) { entry in
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
                    .padding(Theme.Card.inset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 190)
            }
        }
        .card()
    }
}
