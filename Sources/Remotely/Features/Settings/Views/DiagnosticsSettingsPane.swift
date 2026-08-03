import ComposableArchitecture
import RemotelyKit
import SwiftUI

struct DiagnosticsSettingsPane: View {
    let remote: StoreOf<RemoteFeature>

    var body: some View {
        SettingsPane(page: .diagnostics) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    Row(title: "Remote signal") {
                        StatusBadge(
                            title: remote.status.isReady ? "Receiving" : "Awaiting input",
                            tint: remote.status.isReady ? .green : .orange
                        )
                    }
                    HairlineDivider()
                    Row(title: "Accessibility") {
                        StatusBadge(
                            title: remote.hasAccessibility ? "Granted" : "Not granted",
                            tint: remote.hasAccessibility ? .green : .orange
                        )
                    }
                }

                SectionLabel(title: "Events")
                EventLog(remote: remote)
            }
        }
    }
}
