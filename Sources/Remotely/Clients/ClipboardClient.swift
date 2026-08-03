import AppKit
import ComposableArchitecture

@DependencyClient
struct ClipboardClient: Sendable {
    var copy: @Sendable (String) async -> Void
}

extension ClipboardClient: DependencyKey {
    static let liveValue = Self(
        copy: { text in
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        }
    )

    static let testValue = Self(copy: { _ in })
    static let previewValue = testValue
}

extension DependencyValues {
    var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
