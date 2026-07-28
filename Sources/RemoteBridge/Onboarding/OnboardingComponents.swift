import SwiftUI

/// The shared layout every onboarding step uses: hero symbol, title, blurb, and
/// whatever interactive content that step adds underneath.
struct OnboardingStep<Accessory: View>: View {
    let symbol: String
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    init(
        symbol: String,
        title: String,
        detail: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: symbol)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Color.accentColor,
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)

            Text(detail)
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            accessory
                .padding(.top, 2)

            Spacer(minLength: 0)
        }
    }
}

/// A numbered instruction line.
struct OnboardingBullet: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 17, height: 17)
                .background(Color.accentColor, in: Circle())

            Text(text)
                .font(.system(size: 12.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Live pass/fail readout, so a step reflects real state instead of asking the
/// user to take it on faith.
struct OnboardingCheck: View {
    let done: Bool
    let doneText: String
    let waitingText: String

    var body: some View {
        HStack(spacing: 7) {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ProgressView().controlSize(.small)
            }

            Text(done ? doneText : waitingText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(done ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .cardSurface(cornerRadius: Theme.cornerRadius)
    }
}

/// A titled panel used by the practice step.
struct OnboardingPanel<Content: View>: View {
    let hint: String
    let symbol: String
    var badge: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Label(hint, systemImage: symbol)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 6)

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 7)
                        .frame(height: 18)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
            }

            content
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: Theme.cornerRadius)
    }
}
