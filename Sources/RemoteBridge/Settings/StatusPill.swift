import RemoteKit
import SwiftUI

struct StatusPill: View {
    let status: BridgeStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) { pill }
            .buttonStyle(.plain)
            .help(status.detail)
    }

    private var pill: some View {
        HStack(spacing: Theme.Space.icon) {
            IconTile(symbol: status.symbol, tint: status.tint)

            Text(status.title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .dimsWhenInactive()
        .contentShape(Rectangle())
        .padding(.horizontal, Theme.Sidebar.rowInset)
        .frame(height: Theme.Sidebar.rowHeight)
        .background {
            RoundedRectangle(cornerRadius: Theme.Control.radius, style: .continuous)
                .fill(status.tint.opacity(Theme.Opacity.tint))
        }
    }
}
