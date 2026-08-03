import ComposableArchitecture
import LaunchAtLogin

@DependencyClient
struct LaunchAtLoginClient: Sendable {
    var disable: @Sendable () async -> Void
}

extension LaunchAtLoginClient: DependencyKey {
    static let liveValue = Self(
        disable: { await MainActor.run { LaunchAtLogin.isEnabled = false } }
    )

    static let testValue = Self(disable: {})
    static let previewValue = testValue
}

extension DependencyValues {
    var launchAtLoginClient: LaunchAtLoginClient {
        get { self[LaunchAtLoginClient.self] }
        set { self[LaunchAtLoginClient.self] = newValue }
    }
}
