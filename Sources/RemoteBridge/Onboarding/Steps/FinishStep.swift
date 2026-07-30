import SwiftUI

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
                    .init(
                        symbol: "waveform.path.ecg",
                        tint: .orange,
                        label: "Diagnose\nfrom there"
                    ),
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
