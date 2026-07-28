import SwiftUI

/// A live practice area.
///
/// These are ordinary SwiftUI controls, so the remote drives them exactly as it
/// drives the rest of the system. Nothing here is simulated, which is the whole
/// point: if it works here, it works everywhere.
struct PracticeStep: View {
    @ObservedObject var model: BridgeModel

    @State private var clicked: Set<Int> = []

    var body: some View {
        OnboardingStep(
            title: "Try it out",
            hint: model.scrollMode
                ? "Scrolling is on. Press Back twice again to go back to moving."
                : "Press Back twice to switch the arrows between moving and scrolling."
        ) {
            PermissionDialogMock(symbol: "hand.tap.fill", tint: .indigo)
        } accessory: {
            VStack(spacing: 11) {
                VStack(spacing: 9) {
                    Text("Hold an arrow to glide, tap to nudge, press Center to click")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            Button {
                                clicked.insert(index)
                            } label: {
                                Circle()
                                    .fill(clicked.contains(index)
                                          ? Color.green
                                          : Color.primary.opacity(0.13))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if clicked.contains(index) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .cardSurface(cornerRadius: Theme.cardCornerRadius)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(1...14, id: \.self) { row in
                            Text("Scrollable line \(row)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 68)
                .cardSurface(cornerRadius: Theme.cardCornerRadius)
            }
        }
    }
}
