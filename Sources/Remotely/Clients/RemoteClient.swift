import ComposableArchitecture
import Foundation
import RemotelyKit

@DependencyClient
struct RemoteClient: Sendable {
    struct LogEntry: Identifiable, Hashable, Sendable {
        let id = UUID()
        let date: Date
        let message: String

        var time: String { date.formatted(date: .omitted, time: .standard) }
    }

    struct Snapshot: Equatable, Sendable {
        let status: RemoteStatus
        let displayName: String?
        let pressCount: UInt64
        let isScrolling: Bool
        let log: [LogEntry]
        let hasAccessibility: Bool
        let isEnabled: Bool
        let sensitivity: Double
        let bindings: Bindings
    }

    var events: @Sendable () async -> AsyncStream<Snapshot> = { AsyncStream { $0.finish() } }
    var start: @Sendable () async -> Void
    var stop: @Sendable () async -> Void
    var reconnect: @Sendable () async -> Void
    var refreshPermission: @Sendable () async -> Void
    var requestPermission: @Sendable () async -> Void
    var setEnabled: @Sendable (Bool) async -> Void
    var setSensitivity: @Sendable (Double) async -> Void
    var setBinding: @Sendable (ButtonBinding, RemoteButton) async -> Void
    var setAction: @Sendable (RemoteAction, RemoteButton) async -> Void
    var setCombo: @Sendable (KeyCombo, RemoteButton) async -> Void
    var resetBinding: @Sendable (RemoteButton) async -> Void
    var resetAllBindings: @Sendable () async -> Void
    var resetPreferences: @Sendable () async -> Void
    var clearLog: @Sendable () async -> Void
}

extension RemoteClient: DependencyKey {
    static let liveValue = Self(
        events: { await MainActor.run { RemoteClientLive.shared.events() } },
        start: { await MainActor.run { RemoteClientLive.shared.start() } },
        stop: { await MainActor.run { RemoteClientLive.shared.stop() } },
        reconnect: { await MainActor.run { RemoteClientLive.shared.reconnect() } },
        refreshPermission: {
            await MainActor.run { RemoteClientLive.shared.refreshPermission() }
        },
        requestPermission: {
            await MainActor.run { RemoteClientLive.shared.requestPermission() }
        },
        setEnabled: { enabled in
            await MainActor.run { RemoteClientLive.shared.setEnabled(enabled) }
        },
        setSensitivity: { sensitivity in
            await MainActor.run { RemoteClientLive.shared.setSensitivity(sensitivity) }
        },
        setBinding: { binding, button in
            await MainActor.run { RemoteClientLive.shared.setBinding(binding, for: button) }
        },
        setAction: { action, button in
            await MainActor.run { RemoteClientLive.shared.setAction(action, for: button) }
        },
        setCombo: { combo, button in
            await MainActor.run { RemoteClientLive.shared.setCombo(combo, for: button) }
        },
        resetBinding: { button in
            await MainActor.run { RemoteClientLive.shared.resetBinding(for: button) }
        },
        resetAllBindings: {
            await MainActor.run { RemoteClientLive.shared.resetAllBindings() }
        },
        resetPreferences: {
            await MainActor.run { RemoteClientLive.shared.resetPreferences() }
        },
        clearLog: {
            await MainActor.run { RemoteClientLive.shared.clearLog() }
        }
    )

    static let testValue = Self(
        events: { AsyncStream { $0.finish() } },
        start: {},
        stop: {},
        reconnect: {},
        refreshPermission: {},
        requestPermission: {},
        setEnabled: { _ in },
        setSensitivity: { _ in },
        setBinding: { _, _ in },
        setAction: { _, _ in },
        setCombo: { _, _ in },
        resetBinding: { _ in },
        resetAllBindings: {},
        resetPreferences: {},
        clearLog: {}
    )

    static let previewValue = testValue
}

extension DependencyValues {
    var remoteClient: RemoteClient {
        get { self[RemoteClient.self] }
        set { self[RemoteClient.self] = newValue }
    }
}
