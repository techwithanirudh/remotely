import SwiftUI

/// Closing screen.
struct FinishStep: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        ZStack {
            Confetti()

            VStack(spacing: 0) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)

                Text("You're all set")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 4)

                Text("Your remote controls this Mac whenever the TV is on "
                     + "that HDMI input.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                OnboardingIconRow(items: [
                    .init(symbol: "menubar.arrow.up.rectangle", tint: .gray,
                          label: "Lives in the\nmenu bar"),
                    .init(symbol: "dpad.fill", tint: .purple,
                          label: "Remap any\nbutton"),
                    .init(symbol: "waveform.path.ecg", tint: .orange,
                          label: "Diagnose\nfrom there"),
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

/// A short burst of falling confetti.
///
/// Each piece gets a fixed seed so the animation is deterministic per launch
/// and does not re-randomise on every SwiftUI update.
private struct Confetti: View {
    private struct Piece: Identifiable {
        let id: Int
        let x: CGFloat
        let delay: Double
        let duration: Double
        let tint: Color
        let spin: Double
        let size: CGFloat
    }

    private static let palette: [Color] = [
        .pink, .orange, .yellow, .green, .teal, .blue, .purple,
    ]

    private static let pieces: [Piece] = (0..<48).map { index in
        var generator = SeededGenerator(seed: UInt64(index &* 2_654_435_761))
        return Piece(
            id: index,
            x: .random(in: 0...1, using: &generator),
            delay: .random(in: 0...0.9, using: &generator),
            duration: .random(in: 1.6...2.9, using: &generator),
            tint: palette[index % palette.count],
            spin: .random(in: -540...540, using: &generator),
            size: .random(in: 5...9, using: &generator)
        )
    }

    @State private var falling = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ForEach(Self.pieces) { piece in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(piece.tint)
                        .frame(width: piece.size, height: piece.size * 1.6)
                        .rotationEffect(.degrees(falling ? piece.spin : 0))
                        .offset(
                            x: piece.x * geometry.size.width - geometry.size.width / 2,
                            y: falling ? geometry.size.height + 40 : -40
                        )
                        .opacity(falling ? 0 : 1)
                        .animation(
                            .easeIn(duration: piece.duration).delay(piece.delay),
                            value: falling
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
        .onAppear { falling = true }
    }
}

/// Small deterministic generator, so the confetti layout is stable.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B9 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
