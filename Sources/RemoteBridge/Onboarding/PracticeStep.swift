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
            symbol: "hand.tap.fill",
            title: "Try it out",
            detail: "Drive these with the remote. They are real controls, so whatever "
                + "works here works everywhere."
        ) {
            VStack(spacing: 10) {
                OnboardingPanel(
                    hint: "Hold an arrow to glide, tap to fine-tune, then press Center",
                    symbol: "cursorarrow.click",
                    badge: clicked.count == 3 ? "Nice" : nil
                ) {
                    HStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { index in
                            Button {
                                clicked.insert(index)
                            } label: {
                                Circle()
                                    .fill(clicked.contains(index)
                                          ? Color.green
                                          : Color.primary.opacity(0.13))
                                    .frame(width: 32, height: 32)
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

                        Spacer()

                        Text("\(clicked.count)/3")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(clicked.count == 3 ? .green : .secondary)
                    }
                }

                OnboardingPanel(
                    hint: "Press Back twice, then hold an arrow to scroll",
                    symbol: "arrow.up.and.down.text.horizontal",
                    badge: model.scrollMode ? "Scrolling" : nil
                ) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(1...14, id: \.self) { row in
                                Text("Scrollable line \(row)")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 70)
                    .cardSurface(cornerRadius: 8)
                }
            }
        }
    }
}
