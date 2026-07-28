import SwiftUI
import RemoteCore

struct SettingsRootView: View {
    @ObservedObject var model: BridgeModel
    @State private var selection: SettingsPage = .general

    var body: some View {
        // One material for the whole window, with cards floating on top. A
        // separate opaque content pane is what made the right-hand side read as
        // flat white against a translucent sidebar.
        ZStack {
            VisualEffectBackground(material: .underWindowBackground)

            HStack(spacing: 0) {
                SettingsSidebar(selection: $selection, model: model)
                    .frame(width: Theme.sidebarWidth)

                ZStack {
                    Theme.contentWash

                    Group {
                        switch selection {
                        case .general:
                            GeneralSettingsView(model: model)
                        case .connection:
                            ConnectionSettingsView(model: model)
                        case .controls:
                            ControlsSettingsView(model: model)
                        case .diagnostics:
                            DiagnosticsSettingsView(model: model)
                        case .about:
                            AboutSettingsView(model: model)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 740, minHeight: 620)
        .ignoresSafeArea()
    }
}

struct SettingsSidebar: View {
    @Binding var selection: SettingsPage
    @ObservedObject var model: BridgeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clears the traffic lights, which sit in the transparent titlebar.
            StatusPill(status: model.status)
                .padding(.horizontal, Theme.sidebarInset)
                .padding(.top, 40)
                .padding(.bottom, 10)

            SidebarButton(page: .general, selection: $selection)

            SidebarSection(title: "Remote") {
                SidebarButton(page: .connection, selection: $selection)
                SidebarButton(page: .controls, selection: $selection)
            }

            SidebarSection(title: "Support") {
                SidebarButton(page: .diagnostics, selection: $selection)
            }

            Spacer()

            SidebarSection(title: "Remote Bridge") {
                SidebarButton(page: .about, selection: $selection)
            }
            .padding(.bottom, 14)
        }
    }
}

struct StatusPill: View {
    let status: BridgeStatus

    private var tint: Color {
        switch status {
        case .ready: .green
        case .waitingForRemote, .needsPermission: .orange
        case .unsupported, .failed: .red
        case .paused: .secondary
        }
    }

    var body: some View {
        // Built from the same metrics as a sidebar row so the dot lands on the
        // icon rail the window buttons sit on, and the fill lines up with the
        // row backgrounds. A bordered card here fought both.
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
                .frame(width: 22)

            Text(status.title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.sidebarRowPadding)
        .frame(height: Theme.sidebarRowHeight)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(tint.opacity(0.13))
        }
    }
}

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.sidebarInset + Theme.sidebarRowPadding)
                .padding(.top, 14)
                .padding(.bottom, 2)
            content
        }
    }
}

struct SidebarButton: View {
    let page: SettingsPage
    @Binding var selection: SettingsPage

    var body: some View {
        Button {
            selection = page
        } label: {
            HStack(spacing: 10) {
                SymbolTile(symbol: page.symbol, tint: page.tint, size: 22)

                Text(page.title)
                    .font(.system(size: 13, weight: selection == page ? .semibold : .medium))

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, Theme.sidebarRowPadding)
            .frame(height: Theme.sidebarRowHeight)
            .background {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(selection == page ? Theme.selectionFill : .clear)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.sidebarInset)
    }
}
