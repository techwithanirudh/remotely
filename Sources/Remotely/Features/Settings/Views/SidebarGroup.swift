import SwiftUI

struct SidebarGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .dimsWhenInactive()
                .padding(.horizontal, Theme.Sidebar.inset + Theme.Sidebar.rowInset)
                .padding(.top, 14)
                .padding(.bottom, 2)
            content
        }
    }
}
