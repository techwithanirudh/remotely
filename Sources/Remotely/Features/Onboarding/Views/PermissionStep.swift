import ComposableArchitecture
import SwiftUI

struct PermissionStep: View {
    let remote: StoreOf<RemoteFeature>

    var body: some View {
        StepLayout(
            title: "Remotely needs your permission to move the pointer",
            hint: remote.hasAccessibility
                ? nil
                : "Switch on Remotely under Privacy & Security → Accessibility."
        ) {
            DialogMock(symbol: "hand.raised.fill", tint: .orange, badge: "gearshape.fill")
        } content: {
            if remote.hasAccessibility {
                DoneLine(title: "Permission allowed")
            }
        }
    }
}
