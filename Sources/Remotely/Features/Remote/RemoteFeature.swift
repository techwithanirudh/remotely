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
        var log: [RemoteClient.LogEntry] = []
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
        case clearLog
        case snapshot(RemoteClient.Snapshot)
    }

    private enum CancelID {
        case events
    }

    @Dependency(\.remoteClient) var remoteClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.isEnabled):
                let isEnabled = state.isEnabled
                return .run { _ in await remoteClient.setEnabled(isEnabled) }

            case .binding(\.sensitivity):
                let sensitivity = state.sensitivity
                return .run { _ in await remoteClient.setSensitivity(sensitivity) }

            case .binding:
                return .none

            case .start:
                return .run { send in
                    let events = await remoteClient.events()
                    await remoteClient.start()
                    for await snapshot in events {
                        await send(.snapshot(snapshot))
                    }
                }
                .cancellable(id: CancelID.events, cancelInFlight: true)

            case let .setEnabled(isEnabled):
                state.isEnabled = isEnabled
                return .run { _ in await remoteClient.setEnabled(isEnabled) }

            case .stop:
                return .merge(
                    .cancel(id: CancelID.events),
                    .run { _ in await remoteClient.stop() }
                )

            case .reconnect:
                return .run { _ in await remoteClient.reconnect() }

            case .refreshPermission:
                return .run { _ in await remoteClient.refreshPermission() }

            case .requestPermission:
                return .run { send in
                    await remoteClient.requestPermission()
                    await send(.refreshPermission)
                }

            case let .resetBinding(button):
                return .run { _ in await remoteClient.resetBinding(button) }

            case .resetAllBindings:
                return .run { _ in await remoteClient.resetAllBindings() }

            case .resetPreferences:
                state = State()
                return .run { _ in await remoteClient.resetPreferences() }

            case let .setAction(action, button):
                return .run { _ in await remoteClient.setAction(action, button) }

            case let .setBinding(binding, button):
                return .run { _ in await remoteClient.setBinding(binding, button) }

            case let .setCombo(combo, button):
                return .run { _ in await remoteClient.setCombo(combo, button) }

            case .clearLog:
                state.log.removeAll()
                return .run { _ in await remoteClient.clearLog() }

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
