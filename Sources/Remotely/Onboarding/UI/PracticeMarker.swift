import SwiftUI

struct PracticeMarker: View {
    let outcome: PracticeOutcome
    let idleSymbol: String
    let prompt: String

    var body: some View {
        VStack(spacing: 9) {
            Circle()
                .fill(fill)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(outcome == .waiting
                            ? AnyShapeStyle(.secondary)
                            : AnyShapeStyle(Color.white))
                }
                .animation(Theme.Motion.state, value: outcome)

            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, Theme.Card.inset)
        .card()
    }

    private var fill: Color {
        switch outcome {
        case .waiting: .primary.opacity(0.12)
        case .wrong: .orange
        case .passed: .green
        }
    }

    private var symbol: String {
        switch outcome {
        case .waiting: idleSymbol
        case .wrong: "exclamationmark"
        case .passed: "checkmark"
        }
    }

    private var tint: Color {
        switch outcome {
        case .wrong: .orange
        case .passed: .green
        case .waiting: .secondary
        }
    }

    private var caption: String {
        switch outcome {
        case .waiting: prompt
        case .wrong(let reason): reason
        case .passed: "That came from the remote"
        }
    }
}
