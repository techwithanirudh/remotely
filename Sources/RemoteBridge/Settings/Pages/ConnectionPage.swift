import Defaults
import RemoteKit
import SwiftUI

struct ConnectionPage: View {
    @ObservedObject var bridge: RemoteBridge
    @Default(.tvBrand) private var brand

    private var isLinked: Bool { bridge.status.isReady }

    var body: some View {
        PageShell(page: .connection) {
            VStack(alignment: .leading, spacing: 0) {
                Card {
                    HStack(spacing: 13) {
                        Image(systemName: bridge.status.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(bridge.status.tint)
                            .frame(width: 34, height: 34)
                            .background(
                                bridge.status.tint.opacity(0.13),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bridge.status.title).font(.system(size: 14, weight: .semibold))
                            Text(bridge.status.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        if bridge.status == .needsPermission {
                            Button("Allow…") { bridge.requestPermission() }.controlSize(.small)
                        } else {
                            Button("Reconnect") { bridge.reconnect() }.controlSize(.small)
                        }
                    }
                    .padding(Theme.cardPadding)
                }

                SectionLabel(title: "Setup")

                Card {
                    Checklist(text: "Connect this Mac to your TV with an HDMI cable", done: isLinked)
                    Divider1px()
                    Checklist(text: "Switch the TV to that HDMI input", done: isLinked)
                    Divider1px()
                    Checklist(text: "Turn on HDMI-CEC in the TV's settings", done: isLinked)
                }

                SectionLabel(title: "Where to find it")

                Card { BrandGuide(brand: $brand) }
            }
        }
    }
}

private struct Checklist: View {
    let text: String
    let done: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(done ? .green : .secondary)
            Text(text).font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(height: 42)
    }
}

/// Brand picker, that maker's name for HDMI-CEC, the menu path, and a link to
/// their own instructions. Naming a few brands in a footnote left every other
/// owner guessing.
///
/// Three divided rows rather than a stack of left-aligned pieces. The picker
/// and the link each used to float in the middle of their own line, which read
/// as three unrelated fragments, and the link had to be moved for the narrower
/// onboarding panel. As rows, one layout fits both widths.
struct BrandGuide: View {
    @Binding var brand: TVBrand

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Display").font(.system(size: 13))
                Spacer(minLength: 8)

                Picker("", selection: $brand) {
                    ForEach(TVBrand.allCases) { Text($0.name).tag($0) }
                }
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
            }
            .padding(.horizontal, Theme.cardPadding)
            .frame(height: 42)

            Divider1px()

            VStack(alignment: .leading, spacing: 3) {
                Text("Look for “\(brand.featureName)”")
                    .font(.system(size: 12.5, weight: .semibold))

                Text(brand.menuPath)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.cardPadding)
            .padding(.vertical, 10)

            if let url = brand.helpURL {
                Divider1px()
                instructions(url)
            }
        }
    }

    /// Labelled for what it actually is: the maker's page where one is known
    /// to work, a search otherwise.
    private func instructions(_ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 9) {
                Image(systemName: brand.hasVerifiedArticle ? "book.fill" : "magnifyingglass")
                    .font(.system(size: 11))
                    .frame(width: 14)

                Text(brand.hasVerifiedArticle
                     ? "\(brand.name) instructions"
                     : "Search for instructions")
                    .font(.system(size: 12.5))

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, Theme.cardPadding)
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }
}
