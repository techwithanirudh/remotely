import SwiftUI

/// The shared layout every step uses: illustration, headline, content, hint.
struct StepLayout<Hero: View, Content: View>: View {
    let title: String
    var hint: String?
    @ViewBuilder var hero: Hero
    @ViewBuilder var content: Content

    init(
        title: String,
        hint: String? = nil,
        @ViewBuilder hero: () -> Hero,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.hint = hint
        self.hero = hero()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            hero.padding(.bottom, 18)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            content.padding(.top, 18)

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

/// A stand-in for the macOS permission prompt.
///
/// Used only by the step that actually triggers one: showing its shape first is
/// what makes the real prompt recognizable. Elsewhere it was decoration
/// pretending a dialog was coming.
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

/// Row of labelled icons, divided the way Alcove divides its app list.
struct IconRow: View {
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
                    Rectangle().fill(Theme.divider).frame(width: 1, height: 46)
                }

                VStack(spacing: 7) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(item.tint)
                        .frame(height: 22)

                    Text(item.label)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 13)
        .card()
    }
}

/// A step that has been satisfied, said once.
struct DoneLine: View {
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(height: 30)
        .card(radius: Theme.cornerRadius)
    }
}

/// Full-width action, which carries its own waiting state so a blocked step
/// does not need a separate status row saying the same thing.
struct PanelButton: View {
    let title: String
    var isWaiting = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if isWaiting {
                    ProgressView().controlSize(.small).scaleEffect(0.75)
                }
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isWaiting ? Color.secondary : .primary)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardFill.opacity(isWaiting ? 0.5 : 1))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                }
                .brightness(isHovering && !isWaiting ? 0.04 : 0)
        }
        .onHover { isHovering = $0 }
        .disabled(isWaiting)
    }
}

/// Hero for a step that is teaching a gesture rather than previewing a system
/// prompt. The dialog mock only earns its place where a real one follows.
struct GestureHero: View {
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(Theme.tintWashSoft))
                .frame(width: 132, height: 132)

            Circle()
                .fill(tint.opacity(Theme.tintWash))
                .frame(width: 96, height: 96)

            Image(systemName: symbol)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(height: 132)
    }
}
