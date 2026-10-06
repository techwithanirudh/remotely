import SwiftUI

/// A sub-configuration that would crowd its page, Loop's Padding modal being
/// the model: a title, the cards, and one way out.
struct SettingsSheet<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 15, weight: .semibold))

            content

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Page.inset)
        .frame(width: 420)
    }
}
