import RemoteKit
import SwiftUI

struct DiagnosticsSettingsPane: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        SettingsPane(page: .diagnostics) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    Row(title: "Remote signal") {
                        StatusBadge(
                            title: bridge.status.isReady ? "Receiving" : "Awaiting input",
                            tint: bridge.status.isReady ? .green : .orange
                        )
                    }
                    HairlineDivider()
                    Row(title: "Accessibility") {
                        StatusBadge(
                            title: bridge.hasAccessibility ? "Granted" : "Not granted",
                            tint: bridge.hasAccessibility ? .green : .orange
                        )
                    }
                }

                SectionLabel(title: "Events")
                EventLog(bridge: bridge)
            }
        }
    }
}
