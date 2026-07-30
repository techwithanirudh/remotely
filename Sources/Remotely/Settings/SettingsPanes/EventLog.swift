import AppKit
import RemotelyKit
import SwiftUI

struct EventLog: View {
    private enum Layout {
        static let headerHeight: CGFloat = 34
        static let contentHeight: CGFloat = 190
        static let emptyStateLift: CGFloat = 10
    }

    @ObservedObject var remote: Remote

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(remote.log.count) events")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") { remote.clearLog() }
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(remote.logText(), forType: .string)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, Theme.Card.inset)
            .frame(height: Layout.headerHeight)

            HairlineDivider()

            if remote.log.isEmpty {
                ZStack {
                    Text("Remote events will appear here.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .offset(y: -Layout.emptyStateLift)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Layout.contentHeight)
            } else {
                ScrollView {
                    // The newest event must remain visible without following the scroll
                    // position.
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(remote.log.suffix(100).reversed()) { entry in
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
                .frame(height: Layout.contentHeight)
            }
        }
        .card()
    }
}
