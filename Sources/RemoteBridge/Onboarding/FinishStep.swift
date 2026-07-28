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

/// A confetti cannon.
///
/// Pieces fire upward and outward from the bottom of the panel, arc over, then
/// fall past the edge — the shape a real popper makes. Simply dropping them
/// from the top read as weather rather than celebration.
///
/// Each piece carries a fixed seed so the burst is deterministic instead of
/// re-randomising on every SwiftUI update.
private struct Confetti: View {
    fileprivate struct Piece: Identifiable {
        let id: Int
        let fromLeft: Bool
        let spread: CGFloat
        let rise: CGFloat
        let delay: Double
        let duration: Double
        let tint: Color
        let spin: Double
        let width: CGFloat
        let height: CGFloat
        let isCircle: Bool
    }

    private static let palette: [Color] = [
        .pink, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .red,
    ]

    private static let pieces: [Piece] = (0..<120).map { index in
        var generator = SeededGenerator(seed: UInt64(index &* 2_654_435_761 &+ 12_345))
        return Piece(
            id: index,
            fromLeft: index.isMultiple(of: 2),
            spread: .random(in: 60...300, using: &generator),
            rise: .random(in: 220...480, using: &generator),
            delay: .random(in: 0...0.5, using: &generator),
            duration: .random(in: 1.7...2.9, using: &generator),
            tint: palette[index % palette.count],
            spin: .random(in: -1080...1080, using: &generator),
            width: .random(in: 5...10, using: &generator),
            height: .random(in: 9...16, using: &generator),
            isCircle: index.isMultiple(of: 5)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Self.pieces) { piece in
                    piece.shape
                        .fill(piece.tint)
                        .frame(width: piece.width,
                               height: piece.isCircle ? piece.width : piece.height)
                        .keyframeAnimator(
                            initialValue: Flight(),
                            repeating: false
                        ) { view, flight in
                            let angle: Double = piece.spin * Double(flight.travel)
                            let dx: CGFloat = piece.drift * flight.travel
                            view
                                .offset(x: dx, y: flight.height)
                                .rotationEffect(Angle(degrees: angle))
                                .opacity(flight.opacity)
                        } keyframes: { _ in
                            let floor: CGFloat = geometry.size.height / 2
                            let peak: CGFloat = floor - piece.rise
                            let exit: CGFloat = floor + 80

                            KeyframeTrack(\.height) {
                                LinearKeyframe(floor, duration: piece.delay)
                                // Up and over.
                                SpringKeyframe(peak,
                                               duration: piece.duration * 0.45,
                                               spring: .snappy)
                                // Then down past the bottom edge.
                                CubicKeyframe(exit, duration: piece.duration * 0.55)
                            }
                            KeyframeTrack(\.travel) {
                                LinearKeyframe(0, duration: piece.delay)
                                LinearKeyframe(1, duration: piece.duration)
                            }
                            KeyframeTrack(\.opacity) {
                                LinearKeyframe(0, duration: piece.delay)
                                LinearKeyframe(1, duration: 0.05)
                                LinearKeyframe(1, duration: piece.duration * 0.7)
                                LinearKeyframe(0, duration: piece.duration * 0.3)
                            }
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }
}

private extension Confetti.Piece {
    /// Fans outward from whichever side it was fired from.
    var drift: CGFloat { fromLeft ? -spread : spread }

    var shape: AnyShape {
        isCircle
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
    }
}

/// Animatable state for one piece in flight.
private struct Flight {
    var height: CGFloat = 0
    var travel: CGFloat = 0
    var opacity: Double = 0
}

/// Small deterministic generator, so the burst is stable.
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
