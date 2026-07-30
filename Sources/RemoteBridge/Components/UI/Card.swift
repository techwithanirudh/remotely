import SwiftUI

/// Groups rows into one card, with dividers between them.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }.card()
    }
}
