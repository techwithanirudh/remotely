import ComposableArchitecture

@DependencyClient
struct RemotePermissionClient: Sendable {
    var refresh: @Sendable () async -> Void
    var request: @Sendable () async -> Void
}

extension RemotePermissionClient: DependencyKey {
    static let liveValue = Self(
        refresh: { await MainActor.run { RemoteRuntime.shared.refreshPermission() } },
        request: { await MainActor.run { RemoteRuntime.shared.requestPermission() } }
    )

    static let testValue = Self(refresh: {}, request: {})
    static let previewValue = testValue
}

extension DependencyValues {
    var remotePermissionClient: RemotePermissionClient {
        get { self[RemotePermissionClient.self] }
        set { self[RemotePermissionClient.self] = newValue }
    }
}
