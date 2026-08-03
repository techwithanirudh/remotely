import ComposableArchitecture
import Defaults
import RemotelyKit

@Reducer
struct RemoteFeature {
    @ObservableState
    struct State: Equatable {
        var status: RemoteStatus = .paused
        var displayName: String?
        var pressCount: UInt64 = 0
        var isScrolling = false
        var log: [RemoteLogEntry] = []
        var hasAccessibility = false
        var isEnabled = Defaults[.enabled]
        var sensitivity = Defaults[.pointerSensitivity]
        var bindings = Bindings.resolving(Defaults[.bindings])
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case start
        case stop
        case setEnabled(Bool)
        case reconnect
        case refreshPermission
        case requestPermission
        case resetBinding(RemoteButton)
        case resetAllBindings
        case resetPreferences
        case setAction(RemoteAction, RemoteButton)
        case setBinding(ButtonBinding, RemoteButton)
        case setCombo(KeyCombo, RemoteButton)
        case copyLog
        case clearLog
        case snapshot(RemoteSnapshot)
    }

    private enum CancelID {
        case events
    }

    @Dependency(\.remoteSessionClient) var sessionClient
    @Dependency(\.remotePermissionClient) var permissionClient
    @Dependency(\.remoteSettingsClient) var settingsClient
    @Dependency(\.remoteLogClient) var logClient
    @Dependency(\.clipboardClient) var clipboardClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.isEnabled):
                let isEnabled = state.isEnabled
                return .run { _ in await settingsClient.setEnabled(isEnabled) }

            case .binding(\.sensitivity):
                let sensitivity = state.sensitivity
                return .run { _ in await settingsClient.setSensitivity(sensitivity) }

            case .binding:
                return .none

            case .start:
                return .run { send in
                    let events = await sessionClient.events()
                    await sessionClient.start()
                    for await snapshot in events {
                        await send(.snapshot(snapshot))
                    }
                }
                .cancellable(id: CancelID.events, cancelInFlight: true)

            case let .setEnabled(isEnabled):
                state.isEnabled = isEnabled
                return .run { _ in await settingsClient.setEnabled(isEnabled) }

            case .stop:
                return .merge(
                    .cancel(id: CancelID.events),
                    .run { _ in await sessionClient.stop() }
                )

            case .reconnect:
                return .run { _ in await sessionClient.reconnect() }

            case .refreshPermission:
                return .run { _ in await permissionClient.refresh() }

            case .requestPermission:
                return .run { send in
                    await permissionClient.request()
                    await send(.refreshPermission)
                }

            case let .resetBinding(button):
                return .run { _ in await settingsClient.resetBinding(button) }

            case .resetAllBindings:
                return .run { _ in await settingsClient.resetAllBindings() }

            case .resetPreferences:
                state = State()
                return .run { _ in await settingsClient.resetPreferences() }

            case let .setAction(action, button):
                return .run { _ in await settingsClient.setAction(action, button) }

            case let .setBinding(binding, button):
                return .run { _ in await settingsClient.setBinding(binding, button) }

            case let .setCombo(combo, button):
                return .run { _ in await settingsClient.setCombo(combo, button) }

            case .copyLog:
                let text = state.log
                    .map { "\($0.time)  \($0.message)" }
                    .joined(separator: "\n")
                return .run { _ in await clipboardClient.copy(text) }

            case .clearLog:
                state.log.removeAll()
                return .run { _ in await logClient.clear() }

            case let .snapshot(snapshot):
                state.status = snapshot.status
                state.displayName = snapshot.displayName
                state.pressCount = snapshot.pressCount
                state.isScrolling = snapshot.isScrolling
                state.log = snapshot.log
                state.hasAccessibility = snapshot.hasAccessibility
                state.isEnabled = snapshot.isEnabled
                state.sensitivity = snapshot.sensitivity
                state.bindings = snapshot.bindings
                return .none
            }
        }
    }
}
