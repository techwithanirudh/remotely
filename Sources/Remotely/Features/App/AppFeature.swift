import ComposableArchitecture
import Defaults
import RemotelyKit

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        enum Window: Equatable {
            case onboarding
            case settings
        }

        struct WindowRequest: Equatable {
            var destination: Window
            var requestID: UInt = 0
        }

        var remote = RemoteFeature.State()
        var settings = SettingsFeature.State()
        var onboarding = OnboardingFeature.State()
        var window = WindowRequest(
            destination: Defaults[.onboardingDone] ? .settings : .onboarding
        )
    }

    enum Action: Equatable {
        case didFinishLaunching
        case willTerminate
        case reopen
        case menu(MenuAction)
        case window(State.Window)
        case windowClosed(State.Window)
        case remote(RemoteFeature.Action)
        case settings(SettingsFeature.Action)
        case onboarding(OnboardingFeature.Action)

        enum MenuAction: Equatable {
            case toggle
            case settings
            case copyLog
            case checkForUpdates
            case quit
        }
    }

    private enum CancelID {
        case permissionRefresh
    }

    @Dependency(\.applicationClient) var applicationClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.launchAtLoginClient) var launchAtLoginClient

    var body: some ReducerOf<Self> {
        Scope(state: \.remote, action: \.remote) {
            RemoteFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Reduce { state, action in
            switch action {
            case .didFinishLaunching:
                return .merge(
                    .send(.window(state.window.destination)),
                    .send(.remote(.start)),
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .seconds(2)) {
                            await send(.remote(.refreshPermission))
                        }
                    }
                    .cancellable(id: CancelID.permissionRefresh)
                )

            case .willTerminate:
                return .merge(
                    .cancel(id: CancelID.permissionRefresh),
                    .send(.remote(.stop))
                )

            case .reopen:
                return .send(.window(state.window.destination))

            case .menu(.toggle):
                return .send(.remote(.setEnabled(!state.remote.isEnabled)))

            case .menu(.settings):
                return .send(.window(.settings))

            case .menu(.copyLog):
                return .send(.remote(.copyLog))

            case .menu(.checkForUpdates):
                return .send(.settings(.checkForUpdates))

            case .menu(.quit):
                return .run { _ in await applicationClient.terminate() }

            case let .window(window):
                state.window = .init(
                    destination: window,
                    requestID: state.window.requestID &+ 1
                )
                return .merge(
                    .run { _ in await applicationClient.setActivationPolicy(.regular) },
                    window == .settings ? .send(.remote(.refreshPermission)) : .none
                )

            case let .windowClosed(window):
                guard state.window.destination == window else { return .none }
                return .run { _ in await applicationClient.setActivationPolicy(.accessory) }

            case .onboarding(.delegate(.finished)):
                Defaults[.onboardingDone] = true
                return .send(.window(.settings))

            case .settings(.delegate(.replayOnboarding)):
                Defaults[.onboardingDone] = false
                Defaults[.onboardingStep] = 0
                state.onboarding = .init()
                return .send(.window(.onboarding))

            case .settings(.delegate(.factoryReset)):
                Defaults[.onboardingDone] = false
                state.onboarding = .init()
                return .merge(
                    .send(.onboarding(.reset)),
                    .send(.window(.onboarding)),
                    .run { _ in await launchAtLoginClient.disable() },
                    .send(.remote(.resetPreferences))
                )

            case .remote, .settings, .onboarding:
                return .none
            }
        }
    }
}
