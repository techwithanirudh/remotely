import SwiftUI

/// Confetti falling from above.
///
/// Each piece carries a fixed seed, so the fall is stable rather than
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
        /// Where across the width the piece falls, as a fraction from the centre.
        let lane: CGFloat
        let drift: CGFloat
        let start: CGFloat
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
        let sway = CGFloat.random(in: 18...90, using: &random)
        return Piece(
            id: index,
            lane: .random(in: -0.48...0.48, using: &random),
            drift: index.isMultiple(of: 2) ? -sway : sway,
            // Staggered above the top edge, so the fall arrives as a shower
            // rather than one line of pieces crossing together.
            start: .random(in: 40...260, using: &random),
            delay: .random(in: 0...0.8, using: &random),
            duration: .random(in: 2.1...3.4, using: &random),
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
                    .offset(x: piece.lane * size.width + piece.drift * flight.progress, y: flight.height)
                    .rotationEffect(.degrees(piece.spin * Double(flight.progress)))
                    .opacity(flight.opacity)
            } keyframes: { _ in
                let ceiling = -size.height / 2 - piece.start
                let exit = size.height / 2 + 40

                KeyframeTrack(\.height) {
                    LinearKeyframe(ceiling, duration: piece.delay)
                    LinearKeyframe(exit, duration: piece.duration)
                }
                KeyframeTrack(\.progress) {
                    LinearKeyframe(0, duration: piece.delay)
                    LinearKeyframe(1, duration: piece.duration)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: piece.delay)
                    LinearKeyframe(1, duration: 0.12)
                    LinearKeyframe(1, duration: piece.duration * 0.78)
                    LinearKeyframe(0, duration: piece.duration * 0.1)
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
