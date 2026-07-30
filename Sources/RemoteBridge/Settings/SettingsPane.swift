import SwiftUI

struct SettingsPane<Content: View>: View {
    let page: SettingsPage
    @ViewBuilder let content: Content

    var body: some View {
        #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                scroll
                    .safeAreaBar(edge: .top, spacing: 0) { header }
                    .scrollEdgeEffectStyle(.soft, for: .top)
            } else {
                legacyScroll
            }
        #else
            legacyScroll
        #endif
    }

    private var legacyScroll: some View {
        VStack(spacing: 0) {
            header
            scroll.mask(
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)
                    Color.black
                }
            )
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Space.icon) {
            IconTile(symbol: page.symbol, tint: page.tint, size: 23)
            Text(page.title).font(.system(size: 15, weight: .semibold))
            Spacer()
        }
        .dimsWhenInactive()
        .padding(.horizontal, Theme.Page.inset)
        .padding(.top, 15)
        .padding(.bottom, 14)
    }

    private var scroll: some View {
        ScrollView {
            content
                .padding(.horizontal, Theme.Page.inset)
                .padding(.top, 2)
                .padding(.bottom, 32)
        }
    }
}
