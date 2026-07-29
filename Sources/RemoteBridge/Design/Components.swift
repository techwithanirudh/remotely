import SwiftUI

/// Window vibrancy, on `.titlebar` — the material Alcove uses, picked out by
/// capturing all fourteen and comparing them against a capture of its window.
///
/// It follows the window's active state, so losing focus flattens the glass the
/// way Alcove's does.
struct Vibrancy: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .titlebar

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}

/// A tinted rounded-square icon, as used in the sidebar and page headers.
struct IconTile: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.53, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                tint.gradient,
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 9)
            .padding(.top, 20)
            .padding(.bottom, 12)
    }
}

/// Groups rows into one card, with dividers between them.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }.card()
    }
}

/// Spans the full card width rather than being inset to the text, which left
/// the rule starting at a different place than the row above it suggested.
struct Divider1px: View {
    var body: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
    }
}

/// A labelled row with a trailing control.
struct Row<Control: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)
            control
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 9)
        .frame(minHeight: subtitle == nil ? 42 : 56)
    }
}

/// A row that explains something, with a leading symbol.
struct InfoRow: View {
    let symbol: String
    let title: String
    let detail: String
    var tint: Color = .secondary
    var badge: String?

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 22, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    if let badge { Pill(text: badge) }
                    Spacer(minLength: 0)
                }

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 11)
        .frame(minHeight: 50)
    }
}

struct Pill: View {
    let text: String
    var tint: Color = .accentColor

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

struct StatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundStyle(tint)
        }
        .padding(.horizontal, 9)
        .frame(height: 23)
        .background(tint.opacity(0.12), in: Capsule())
    }
}
