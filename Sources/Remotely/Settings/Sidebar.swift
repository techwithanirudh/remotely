import RemotelyKit
import SwiftUI

struct Sidebar: View {
    @Binding var page: SettingsPage
    @ObservedObject var remote: Remote

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusPill(status: remote.status) {
                if remote.status == .needsPermission {
                    remote.requestPermission()
                } else {
                    page = .connection
                }
            }
            .padding(.horizontal, Theme.Sidebar.inset)
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
                .padding(.bottom, Theme.Sidebar.inset)
        }
    }
}
