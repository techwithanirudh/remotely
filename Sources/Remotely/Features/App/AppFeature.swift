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

        var remote = RemoteFeature.State()
        var settings = SettingsFeature.State()
        var onboarding = OnboardingFeature.State()
        var window: Window = Defaults[.onboardingDone] ? .settings : .onboarding
    }

    enum Action: Equatable {
        case didFinishLaunching
        case window(State.Window)
        case remote(RemoteFeature.Action)
        case settings(SettingsFeature.Action)
        case onboarding(OnboardingFeature.Action)
    }

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
                return .send(.remote(.start))

            case let .window(window):
                state.window = window
                return .none

            case .onboarding(.delegate(.finished)):
                Defaults[.onboardingDone] = true
                state.window = .settings
                return .none

            case .settings(.delegate(.replayOnboarding)):
                Defaults[.onboardingDone] = false
                Defaults[.onboardingStep] = 0
                state.onboarding = .init()
                state.window = .onboarding
                return .none

            case .settings(.delegate(.factoryReset)):
                Defaults[.onboardingDone] = false
                state.onboarding = .init()
                state.window = .onboarding
                return .merge(
                    .send(.onboarding(.reset)),
                    .run { _ in await launchAtLoginClient.disable() },
                    .send(.remote(.resetPreferences))
                )

            case .remote, .settings, .onboarding:
                return .none
            }
        }
    }
}
