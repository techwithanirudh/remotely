import SwiftUI

struct SidebarItem: View {
    let page: SettingsPage
    @Binding var selection: SettingsPage

    var body: some View {
        Button {
            selection = page
        } label: {
            HStack(spacing: Theme.Space.icon) {
                IconTile(symbol: page.symbol, tint: page.tint)
                Text(page.title)
                    .font(.system(size: 13, weight: selection == page ? .medium : .regular))
                Spacer()
            }
            .dimsWhenInactive()
            .contentShape(Rectangle())
            .padding(.horizontal, Theme.Sidebar.rowInset)
            .frame(height: Theme.Sidebar.rowHeight)
            .background {
                RoundedRectangle(cornerRadius: Theme.Control.radius, style: .continuous)
                    .fill(selection == page ? Theme.Color.selection : .clear)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Sidebar.inset)
    }
}
