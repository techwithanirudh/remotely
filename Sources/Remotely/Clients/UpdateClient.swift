import ComposableArchitecture
import Foundation
import RemotelyKit

@DependencyClient
struct UpdateClient: Sendable {
    struct Snapshot: Equatable, Sendable {
        var canCheck = false
        var lastCheck: Date?
        var checksAutomatically = true
        var installsAutomatically = false
        var channel: ReleaseChannel = .stable
        var availableVersion: String?
    }

    var snapshot: @Sendable () async -> Snapshot = { Snapshot() }
    var checkForUpdates: @Sendable () async -> Void
    /// Checks the feed silently; the answer arrives through `availability`.
    var probe: @Sendable () async -> Void
    var availability: @Sendable () async -> AsyncStream<String?> = { .finished }
    var setChecksAutomatically: @Sendable (Bool) async -> Void
    var setInstallsAutomatically: @Sendable (Bool) async -> Void
    var setChannel: @Sendable (ReleaseChannel) async -> Void
}

extension UpdateClient: DependencyKey {
    static let liveValue = Self(
        snapshot: { await MainActor.run { UpdateClientLive.shared.snapshot() } },
        checkForUpdates: { await MainActor.run { UpdateClientLive.shared.checkForUpdates() } },
        probe: { await MainActor.run { UpdateClientLive.shared.probe() } },
        availability: { await MainActor.run { UpdateClientLive.shared.availability() } },
        setChecksAutomatically: { value in
            await MainActor.run { UpdateClientLive.shared.setChecksAutomatically(value) }
        },
        setInstallsAutomatically: { value in
            await MainActor.run { UpdateClientLive.shared.setInstallsAutomatically(value) }
        },
        setChannel: { channel in
            await MainActor.run { UpdateClientLive.shared.setChannel(channel) }
        }
    )

    static let testValue = Self()
    static let previewValue = testValue
}

extension DependencyValues {
    var updateClient: UpdateClient {
        get { self[UpdateClient.self] }
        set { self[UpdateClient.self] = newValue }
    }
}
