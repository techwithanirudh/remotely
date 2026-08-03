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
    }

    var snapshot: @Sendable () async -> Snapshot = { Snapshot() }
    var checkForUpdates: @Sendable () async -> Void
    var setChecksAutomatically: @Sendable (Bool) async -> Void
    var setInstallsAutomatically: @Sendable (Bool) async -> Void
    var setChannel: @Sendable (ReleaseChannel) async -> Void
}

extension UpdateClient: DependencyKey {
    static let liveValue: Self = {
        let live = UpdateClientLive.shared
        return Self(
            snapshot: { await live.snapshot() },
            checkForUpdates: { await live.checkForUpdates() },
            setChecksAutomatically: { value in await live.setChecksAutomatically(value) },
            setInstallsAutomatically: { value in await live.setInstallsAutomatically(value) },
            setChannel: { channel in await live.setChannel(channel) }
        )
    }()

    static let testValue = Self()
    static let previewValue = testValue
}

extension DependencyValues {
    var updateClient: UpdateClient {
        get { self[UpdateClient.self] }
        set { self[UpdateClient.self] = newValue }
    }
}

@MainActor
private final class UpdateClientLive: @unchecked Sendable {
    static let shared = UpdateClientLive()

    private let updater = Updater.shared

    func snapshot() -> UpdateClient.Snapshot {
        UpdateClient.Snapshot(
            canCheck: updater.canCheck,
            lastCheck: updater.lastCheck,
            checksAutomatically: updater.checksAutomatically,
            installsAutomatically: updater.installsAutomatically,
            channel: updater.channel
        )
    }

    func checkForUpdates() { updater.checkForUpdates() }
    func setChecksAutomatically(_ value: Bool) { updater.checksAutomatically = value }
    func setInstallsAutomatically(_ value: Bool) { updater.installsAutomatically = value }
    func setChannel(_ channel: ReleaseChannel) { updater.channel = channel }
}
