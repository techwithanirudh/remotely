import SwiftUI

/// Spans the full card width rather than being inset to the text, which left
/// the rule starting at a different place than the row above it suggested.
struct HairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
    }
}
