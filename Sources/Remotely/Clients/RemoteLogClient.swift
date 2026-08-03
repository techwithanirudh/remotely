import ComposableArchitecture

@DependencyClient
struct RemoteLogClient: Sendable {
    var clear: @Sendable () async -> Void
}

extension RemoteLogClient: DependencyKey {
    static let liveValue = Self(
        clear: { await MainActor.run { RemoteRuntime.shared.clearLog() } }
    )

    static let testValue = Self(clear: {})
    static let previewValue = testValue
}

extension DependencyValues {
    var remoteLogClient: RemoteLogClient {
        get { self[RemoteLogClient.self] }
        set { self[RemoteLogClient.self] = newValue }
    }
}
