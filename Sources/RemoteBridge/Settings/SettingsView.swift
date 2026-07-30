import RemoteKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var bridge: RemoteBridge
    @State private var page: SettingsPage = .general
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        ZStack {
            // The cool grey is the material's own tint, not an NSColor, so the
            // material has to stay. The window is not opaque, so behind it also
            // needs a fill under the material or the desktop still reads through.
            if activeState == .inactive {
                Color(nsColor: .windowBackgroundColor)
                Vibrancy(blendingMode: .withinWindow)
            } else {
                Vibrancy()
            }

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
