import ComposableArchitecture
import RemotelyKit

@DependencyClient
struct RemoteSettingsClient: Sendable {
    var setEnabled: @Sendable (Bool) async -> Void
    var setSensitivity: @Sendable (Double) async -> Void
    var setBinding: @Sendable (ButtonBinding, RemoteButton) async -> Void
    var setAction: @Sendable (RemoteAction, RemoteButton) async -> Void
    var setCombo: @Sendable (KeyCombo, RemoteButton) async -> Void
    var resetBinding: @Sendable (RemoteButton) async -> Void
    var resetAllBindings: @Sendable () async -> Void
    var resetPreferences: @Sendable () async -> Void
}

extension RemoteSettingsClient: DependencyKey {
    static let liveValue = Self(
        setEnabled: { enabled in
            await MainActor.run { RemoteRuntime.shared.setEnabled(enabled) }
        },
        setSensitivity: { sensitivity in
            await MainActor.run { RemoteRuntime.shared.setSensitivity(sensitivity) }
        },
        setBinding: { binding, button in
            await MainActor.run { RemoteRuntime.shared.setBinding(binding, for: button) }
        },
        setAction: { action, button in
            await MainActor.run { RemoteRuntime.shared.setAction(action, for: button) }
        },
        setCombo: { combo, button in
            await MainActor.run { RemoteRuntime.shared.setCombo(combo, for: button) }
        },
        resetBinding: { button in
            await MainActor.run { RemoteRuntime.shared.resetBinding(for: button) }
        },
        resetAllBindings: {
            await MainActor.run { RemoteRuntime.shared.resetAllBindings() }
        },
        resetPreferences: {
            await MainActor.run { RemoteRuntime.shared.resetPreferences() }
        }
    )

    static let testValue = Self(
        setEnabled: { _ in },
        setSensitivity: { _ in },
        setBinding: { _, _ in },
        setAction: { _, _ in },
        setCombo: { _, _ in },
        resetBinding: { _ in },
        resetAllBindings: {},
        resetPreferences: {}
    )

    static let previewValue = testValue
}

extension DependencyValues {
    var remoteSettingsClient: RemoteSettingsClient {
        get { self[RemoteSettingsClient.self] }
        set { self[RemoteSettingsClient.self] = newValue }
    }
}
