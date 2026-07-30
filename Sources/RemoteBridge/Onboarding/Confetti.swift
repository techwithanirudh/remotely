import ConfettiSwiftUI
import SwiftUI

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
