import RemoteKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var bridge: RemoteBridge
    @State private var page: SettingsPage = .general
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        ZStack {
            Vibrancy(material: activeState == .inactive ? .contentBackground :
                .underWindowBackground)

            HStack(spacing: 0) {
                Sidebar(page: $page, bridge: bridge)
                    .frame(width: Theme.Sidebar.width)

                Rectangle()
                    .fill(Theme.Color.divider)
                    .frame(width: 1)

                page(for: page).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Applying this after ignoresSafeArea moves its lit edge 32pt below the window.
        .overlay(WindowEdgeHighlight())
        .frame(minWidth: 660, minHeight: 600)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func page(for page: SettingsPage) -> some View {
        switch page {
        case .general: GeneralSettingsPane(bridge: bridge)
        case .connection: ConnectionSettingsPane(bridge: bridge)
        case .controls: ControlsSettingsPane(bridge: bridge)
        case .diagnostics: DiagnosticsSettingsPane(bridge: bridge)
        case .about: AboutSettingsPane()
        }
    }
}
