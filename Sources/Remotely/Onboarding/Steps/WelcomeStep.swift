import RemotelyKit
import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 0) {
            AppIconButton(size: 76)

            Text("Remotely")
                .font(.system(size: 27, weight: .bold))
                .padding(.top, 2)

            Text("Your TV remote becomes a pointer for this Mac, "
                + "over the HDMI cable you already have.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            IconRow(items: [
                .init(symbol: RemoteAction.moveUp.symbol,
                      tint: .blue, label: "Hold to\nmove"),
                .init(
                    symbol: RemoteAction.leftClick.symbol,
                    tint: .purple,
                    label: "Center to\nclick"
                ),
                .init(symbol: RemoteAction.toggleScrolling.symbol,
                      tint: .teal, label: "Back twice\nto scroll"),
            ])
            .padding(.top, 20)
        }
    }
}
