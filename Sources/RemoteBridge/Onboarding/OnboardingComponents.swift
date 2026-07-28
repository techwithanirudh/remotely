import SwiftUI

/// The shared layout every onboarding step uses.
///
/// Modelled on Alcove's: a borderless portrait panel, an illustration up top, a
/// centred headline, supporting content, then a full-width action. There is no
/// titlebar, so nothing has to line up with window buttons.
struct OnboardingStep<Hero: View, Accessory: View>: View {
    let title: String
    var hint: String?
    @ViewBuilder var hero: Hero
    @ViewBuilder var accessory: Accessory

    init(
        title: String,
        hint: String? = nil,
        @ViewBuilder hero: () -> Hero,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.hint = hint
        self.hero = hero()
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 0) {
            hero
                .padding(.bottom, 18)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            accessory
                .padding(.top, 18)

            if let hint {
                Text(hint)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)
            }
        }
    }
}

/// A stand-in for the system dialog the user is about to see. Showing the shape
/// of it up front is what makes the real prompt recognisable when it appears.
struct PermissionDialogMock: View {
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
                Capsule().fill(Color.primary.opacity(0.22)).frame(width: 108, height: 5)
                Capsule().fill(Color.primary.opacity(0.13)).frame(width: 62, height: 5)
            }

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.10))
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
        .cardSurface(cornerRadius: 14)
    }
}

/// Row of labelled icons, divided the way Alcove divides its app list.
struct OnboardingIconRow: View {
    struct Item: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
        let label: String
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.divider)
                        .frame(width: 1, height: 46)
                }

                VStack(spacing: 7) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(item.tint)
                        .frame(height: 24)

                    Text(item.label)
                        .font(.system(size: 11.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 13)
        .cardSurface(cornerRadius: Theme.cardCornerRadius)
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
                .font(.system(size: 12))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
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
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(done ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .cardSurface(cornerRadius: Theme.cornerRadius)
    }
}

/// Alcove's full-width, card-styled action button.
struct OnboardingButton: View {
    let title: String
    var prominent = true
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? Color.primary : Color.secondary)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(prominent ? Theme.cardFill : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(prominent ? Theme.cardStroke : .clear, lineWidth: 1)
                }
                .brightness(hovering && prominent ? 0.04 : 0)
        }
        .onHover { hovering = $0 }
    }
}
