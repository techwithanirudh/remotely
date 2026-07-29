import SwiftUI

/// A confetti cannon.
///
/// Pieces fire up and out from the bottom, arc over, then fall past the edge —
/// the shape a popper makes. Dropping them from the top read as weather.
/// Each piece carries a fixed seed, so the burst is stable rather than
/// re-randomising on every SwiftUI update.
struct Confetti: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Self.pieces) { piece in
                    Flake(piece: piece, size: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }

    fileprivate struct Piece: Identifiable {
        let id: Int
        let drift: CGFloat
        let rise: CGFloat
        let delay: Double
        let duration: Double
        let tint: Color
        let spin: Double
        let width: CGFloat
        let height: CGFloat
        let isRound: Bool
    }

    private static let palette: [Color] = [
        .pink, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .red,
    ]

    fileprivate static let pieces: [Piece] = (0..<120).map { index in
        var random = Seeded(seed: UInt64(index &* 2_654_435_761 &+ 12_345))
        let spread = CGFloat.random(in: 60...300, using: &random)
        return Piece(
            id: index,
            drift: index.isMultiple(of: 2) ? -spread : spread,
            rise: .random(in: 220...480, using: &random),
            delay: .random(in: 0...0.5, using: &random),
            duration: .random(in: 1.7...2.9, using: &random),
            tint: palette[index % palette.count],
            spin: .random(in: -1080...1080, using: &random),
            width: .random(in: 5...10, using: &random),
            height: .random(in: 9...16, using: &random),
            isRound: index.isMultiple(of: 5)
        )
    }
}

private struct Flake: View {
    let piece: Confetti.Piece
    let size: CGSize

    /// Driven by a trigger rather than `repeating: false`, which never ran the
    /// animation: the pieces sat at their initial value, invisible.
    @State private var launched = false

    var body: some View {
        shape
            .fill(piece.tint)
            .frame(width: piece.width, height: piece.isRound ? piece.width : piece.height)
            .keyframeAnimator(initialValue: Flight(), trigger: launched) { view, flight in
                view
                    .offset(x: piece.drift * flight.progress, y: flight.height)
                    .rotationEffect(.degrees(piece.spin * Double(flight.progress)))
                    .opacity(flight.opacity)
            } keyframes: { _ in
                let floor = size.height / 2
                let peak = floor - piece.rise
                let exit = floor + 80

                KeyframeTrack(\.height) {
                    LinearKeyframe(floor, duration: piece.delay)
                    SpringKeyframe(peak, duration: piece.duration * 0.45, spring: .snappy)
                    CubicKeyframe(exit, duration: piece.duration * 0.55)
                }
                KeyframeTrack(\.progress) {
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
            .onAppear { launched = true }
    }

    private var shape: AnyShape {
        piece.isRound
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
    }
}

private struct Flight {
    var height: CGFloat = 0
    var progress: CGFloat = 0
    var opacity: Double = 0
}

/// Deterministic generator, so the burst is the same every time.
private struct Seeded: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
