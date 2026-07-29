import ConfettiSwiftUI
import SwiftUI

/// Rains from the top of the panel, once, when the last step appears.
///
/// ConfettiSwiftUI rather than a hand-rolled burst. Its cannon fires into a
/// cone, and the cone's angles run anticlockwise from east: the default 60 to
/// 120 fires upward, so a fall needs 180 to 360.
struct Confetti: View {
    @State private var trigger = 0

    private static let palette: [Color] = [
        .pink, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .red,
    ]

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 1)
                .confettiCannon(
                    trigger: $trigger,
                    num: 80,
                    confettis: [.shape(.circle)],
                    colors: Self.palette,
                    confettiSize: 9,
                    rainHeight: 640,
                    openingAngle: .degrees(180),
                    closingAngle: .degrees(360),
                    radius: 240,
                    hapticFeedback: false
                )

            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
        .onAppear { trigger += 1 }
    }
}
