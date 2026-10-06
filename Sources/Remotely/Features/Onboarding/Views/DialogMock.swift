import SwiftUI

struct DialogMock: View {
    let symbol: String
    let tint: Color
    var badge: String?

    var body: some View {
        VStack(spacing: 13) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(tint, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                if let badge {
                    Image(systemName: badge)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Color.secondary,
                            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                        )
                        .offset(x: 7, y: 7)
                }
            }
            .padding(.top, 4)

            VStack(spacing: 5) {
                Capsule().fill(.primary.opacity(0.22)).frame(width: 108, height: 5)
                Capsule().fill(.primary.opacity(0.13)).frame(width: 62, height: 5)
            }

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.primary.opacity(0.10))
                    .frame(width: 52, height: 22)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: 52, height: 22)
                    .overlay {
                        Capsule().fill(.white.opacity(0.75)).frame(width: 24, height: 4)
                    }
            }
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .card(radius: 14)
    }
}
