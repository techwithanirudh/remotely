import RemoteKit
import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case general, connection, controls, diagnostics, about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .connection: "Connection"
        case .controls: "Controls"
        case .diagnostics: "Diagnostics"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .connection: "cable.connector"
        case .controls: "dpad.fill"
        case .diagnostics: "waveform.path.ecg"
        case .about: "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general: .gray
        case .connection: .cyan
        case .controls: .purple
        case .diagnostics: .orange
        case .about: .gray
        }
    }
}

struct SettingsView: View {
    @ObservedObject var bridge: RemoteBridge
    @State private var page: SettingsPage = .general

    var body: some View {
        // One material and one tint across the whole window, split by a
        // hairline. Washing the content side a second shade made the two halves
        // read as different surfaces.
        ZStack {
            Vibrancy()

            HStack(spacing: 0) {
                Sidebar(page: $page, bridge: bridge)
                    .frame(width: Theme.sidebarWidth)

                Rectangle()
                    .fill(Theme.divider)
                    .frame(width: 1)

                page(for: page).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // The highlight goes on before the safe area is ignored. Applied after,
        // the overlay is laid out inside the safe area, so its lit top edge
        // landed 32pt down and read as a bar across the whole window.
        .overlay(WindowEdgeHighlight())
        .frame(minWidth: 740, minHeight: 620)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func page(for page: SettingsPage) -> some View {
        switch page {
        case .general: GeneralPage(bridge: bridge)
        case .connection: ConnectionPage(bridge: bridge)
        case .controls: ControlsPage(bridge: bridge)
        case .diagnostics: DiagnosticsPage(bridge: bridge)
        case .about: AboutPage(bridge: bridge)
        }
    }
}

/// Page scaffold: title header, then scrolling content.
struct PageShell<Content: View>: View {
    let page: SettingsPage
    @ViewBuilder let content: Content

    var body: some View {
        // On macOS 26 the title is a bar, not an inset. Both reserve the space,
        // but only `safeAreaBar` extends the scroll view's edge effect into it,
        // which is what blurs content as it passes under the title. An inset
        // left the effect sitting at the top of the content instead, cutting
        // across the page. Before macOS 26 there is no such effect at all, so
        // content is faded out with a mask: masking to clear works over
        // vibrancy, where painting a solid strip would not.
        if #available(macOS 26.0, *) {
            scroll
                .safeAreaBar(edge: .top, spacing: 0) { header }
                .scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            VStack(spacing: 0) {
                header
                scroll.mask(
                    VStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                            .frame(height: 16)
                        Color.black
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            IconTile(symbol: page.symbol, tint: page.tint, size: 23)
            Text(page.title).font(.system(size: 15, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, Theme.pageInset)
        .padding(.top, 15)
        .padding(.bottom, 14)
    }

    private var scroll: some View {
        ScrollView {
            content
                .padding(.horizontal, Theme.pageInset)
                .padding(.top, 2)
                .padding(.bottom, 32)
        }
    }
}

private struct Sidebar: View {
    @Binding var page: SettingsPage
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clears the window buttons, which sit in the transparent titlebar.
            StatusPill(status: bridge.status)
                .padding(.horizontal, Theme.sidebarInset)
                .padding(.top, 44)
                .padding(.bottom, 10)

            SidebarItem(page: .general, selection: $page)

            SidebarGroup(title: "Remote") {
                SidebarItem(page: .connection, selection: $page)
                SidebarItem(page: .controls, selection: $page)
            }

            SidebarGroup(title: "Support") {
                SidebarItem(page: .diagnostics, selection: $page)
            }

            Spacer()

            SidebarItem(page: .about, selection: $page)
                .padding(.bottom, 14)
        }
    }
}

/// Built from the same metrics as a sidebar row, so it sits on the rail the
/// window buttons and row icons share.
///
/// It carries a full tile rather than a bare dot: an 8pt dot was on the right
/// rail arithmetically, but next to rows of 22pt tiles its visual weight sat
/// well inside them and read as off-centre.
private struct StatusPill: View {
    let status: BridgeStatus

    var body: some View {
        HStack(spacing: 10) {
            IconTile(symbol: status.symbol, tint: status.tint)

            Text(status.title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.rowPadding)
        .frame(height: Theme.rowHeight)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(status.tint.opacity(0.13))
        }
    }
}

private struct SidebarGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.sidebarInset + Theme.rowPadding)
                .padding(.top, 14)
                .padding(.bottom, 2)
            content
        }
    }
}

private struct SidebarItem: View {
    let page: SettingsPage
    @Binding var selection: SettingsPage

    var body: some View {
        Button {
            selection = page
        } label: {
            HStack(spacing: 10) {
                IconTile(symbol: page.symbol, tint: page.tint)
                Text(page.title)
                    .font(.system(size: 13, weight: selection == page ? .semibold : .medium))
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, Theme.rowPadding)
            .frame(height: Theme.rowHeight)
            .background {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(selection == page ? Theme.selection : .clear)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.sidebarInset)
    }
}

extension BridgeStatus {
    var tint: Color {
        switch self {
        case .ready: .green
        case .waitingForRemote, .needsPermission: .orange
        case .unsupported, .failed: .red
        case .paused: .secondary
        }
    }
}
