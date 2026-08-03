import ComposableArchitecture

@DependencyClient
struct RemoteSessionClient: Sendable {
    var events: @Sendable () async -> AsyncStream<RemoteSnapshot> = {
        AsyncStream { $0.finish() }
    }

    var start: @Sendable () async -> Void
    var stop: @Sendable () async -> Void
    var reconnect: @Sendable () async -> Void
}

extension RemoteSessionClient: DependencyKey {
    static let liveValue = Self(
        events: { await MainActor.run { RemoteRuntime.shared.events() } },
        start: { await MainActor.run { RemoteRuntime.shared.start() } },
        stop: { await MainActor.run { RemoteRuntime.shared.stop() } },
        reconnect: { await MainActor.run { RemoteRuntime.shared.reconnect() } }
    )

    static let testValue = Self(
        events: { AsyncStream { $0.finish() } },
        start: {},
        stop: {},
        reconnect: {}
    )

    static let previewValue = testValue
}

extension DependencyValues {
    var remoteSessionClient: RemoteSessionClient {
        get { self[RemoteSessionClient.self] }
        set { self[RemoteSessionClient.self] = newValue }
    }
}
