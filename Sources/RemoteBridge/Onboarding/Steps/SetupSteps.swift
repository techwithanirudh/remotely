import RemoteKit
import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 76, height: 76)

            Text("Remote Bridge")
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
                .init(symbol: "arrow.up.and.down.and.arrow.left.and.right",
                      tint: .blue, label: "Hold to\nmove"),
                .init(symbol: "cursorarrow.click", tint: .purple, label: "Center to\nclick"),
                .init(symbol: "arrow.up.and.down.text.horizontal",
                      tint: .teal, label: "Back twice\nto scroll"),
            ])
            .padding(.top, 20)

            Text("No extra hardware, no dongle, no subscription.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.top, 18)
        }
    }
}

struct ConnectStep: View {
    @Binding var brand: TVBrand

    var body: some View {
        StepLayout(
            title: "Connect over HDMI",
            hint: "Plug in the cable and switch the TV to that input, then turn on "
                + "HDMI-CEC in its settings."
        ) {
            GestureHero(symbol: "cable.connector", tint: .cyan)
        } content: {
            BrandGuide(brand: $brand, isCompact: true).card(radius: Theme.cornerRadius)
        }
    }
}

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
                StatusLine(done: true, doneText: "Permission allowed", waitingText: "")
            }
        }
    }
}

struct FinishStep: View {
    var body: some View {
        ZStack {
            Confetti()

            VStack(spacing: 0) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)

                Text("You're all set")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 4)

                Text("Your remote controls this Mac whenever the TV is on that HDMI input.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                IconRow(items: [
                    .init(symbol: "menubar.arrow.up.rectangle", tint: .gray,
                          label: "Lives in the\nmenu bar"),
                    .init(symbol: "dpad.fill", tint: .purple, label: "Remap any\nbutton"),
                    .init(symbol: "waveform.path.ecg", tint: .orange, label: "Diagnose\nfrom there"),
                ])
                .padding(.top, 20)

                Text("Run this guide again any time from About.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 18)
            }
        }
    }
}
