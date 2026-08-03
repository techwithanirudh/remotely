import ComposableArchitecture
import RemotelyKit
import SwiftUI

struct Sidebar: View {
    @Bindable var store: StoreOf<SettingsFeature>
    let remote: StoreOf<RemoteFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusPill(status: remote.status) {
                if remote.status == .needsPermission {
                    remote.send(.requestPermission)
                } else {
                    store.send(.selectPage(.connection))
                }
            }
            .padding(.horizontal, Theme.Sidebar.inset)
            .padding(.top, 44)
            .padding(.bottom, 10)

            SidebarItem(page: .general, selection: $store.page)

            SidebarGroup(title: "Remote") {
                SidebarItem(page: .connection, selection: $store.page)
                SidebarItem(page: .controls, selection: $store.page)
            }

            SidebarGroup(title: "Support") {
                SidebarItem(page: .diagnostics, selection: $store.page)
            }

            Spacer()

            SidebarItem(page: .about, selection: $store.page)
                .padding(.bottom, Theme.Sidebar.inset)
        }
    }
}
