import SwiftUI

/// The borderless picker every row uses, rather than the style repeated inline.
struct Select<Value: Hashable, Content: View>: View {
    @Binding var selection: Value
    @ViewBuilder var content: Content

    var body: some View {
        Picker("", selection: $selection) { content }
            .labelsHidden()
            .buttonStyle(.borderless)
            .fixedSize()
    }
}
