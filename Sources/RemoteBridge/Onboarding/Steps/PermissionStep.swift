import RemoteKit
import SwiftUI

struct PermissionStep: View {
    @ObservedObject var bridge: RemoteBridge

    var body: some View {
        StepLayout(
            title: "Remote Bridge needs your permission to move the pointer",
            hint: bridge.hasAccessibility
                ? nil
                : "Switch on Remote Bridge under Privacy & Security → Accessibility."
        ) {
            DialogMock(symbol: "hand.raised.fill", tint: .orange, badge: "gearshape.fill")
        } content: {
            if bridge.hasAccessibility {
                DoneLine(title: "Permission allowed")
            }
        }
    }
}
