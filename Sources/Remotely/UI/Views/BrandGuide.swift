import RemotelyKit
import SwiftUI

struct BrandGuide: View {
    @Binding var brand: TVBrand

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Display").font(.system(size: 13))
                Spacer(minLength: 8)

                Select(selection: $brand) {
                    ForEach(TVBrand.allCases) { Text($0.name).tag($0) }
                }
            }
            .padding(.horizontal, Theme.Card.inset)
            .frame(height: Theme.Card.rowHeight)

            HairlineDivider()

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
            .padding(.horizontal, Theme.Card.inset)
            .padding(.vertical, 10)

            if let url = brand.helpURL {
                HairlineDivider()
                instructions(url)
            }
        }
    }

    private func instructions(_ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: Theme.Space.icon) {
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
            .padding(.horizontal, Theme.Card.inset)
            .frame(height: Theme.Card.rowHeight)
        }
        .buttonStyle(.plain)
    }
}
