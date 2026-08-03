import AppKit
import ComposableArchitecture

enum AppActivationPolicy: Sendable {
    case accessory
    case regular
}

@DependencyClient
struct ApplicationClient: Sendable {
    var setActivationPolicy: @Sendable (AppActivationPolicy) async -> Void
    var terminate: @Sendable () async -> Void
}

extension ApplicationClient: DependencyKey {
    static let liveValue = Self(
        setActivationPolicy: { policy in
            await MainActor.run {
                _ = NSApp.setActivationPolicy(policy == .regular ? .regular : .accessory)
            }
        },
        terminate: {
            await MainActor.run { NSApp.terminate(nil) }
        }
    )

    static let testValue = Self(
        setActivationPolicy: { _ in },
        terminate: {}
    )

    static let previewValue = testValue
}

extension DependencyValues {
    var applicationClient: ApplicationClient {
        get { self[ApplicationClient.self] }
        set { self[ApplicationClient.self] = newValue }
    }
}
