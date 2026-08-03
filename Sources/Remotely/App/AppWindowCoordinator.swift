import AppKit
import Combine
import ComposableArchitecture

@MainActor
final class AppWindowCoordinator {
    private let store: StoreOf<AppFeature>
    private var settings: SettingsWindowController?
    private var onboarding: OnboardingWindowController?
    private var observers = Set<AnyCancellable>()

    init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    func start() {
        store.publisher.window
            .removeDuplicates()
            .sink { [weak self] request in
                self?.render(request.destination)
            }
            .store(in: &observers)
        render(store.window.destination)
    }
}

private extension AppWindowCoordinator {
    func render(_ window: AppFeature.State.Window) {
        switch window {
        case .settings:
            showSettings()
        case .onboarding:
            showOnboarding()
        }
    }

    func showSettings() {
        onboarding?.close()
        onboarding = nil

        if settings == nil {
            let controller = SettingsWindowController(
                settings: store.scope(state: \.settings, action: \.settings),
                remote: store.scope(state: \.remote, action: \.remote)
            )
            controller.onClose = { [weak self] in
                self?.store.send(.windowClosed(.settings))
            }
            settings = controller
        }
        settings?.show()
    }

    /// Reuses the open guide; a second one left two panels on their own steps.
    func showOnboarding() {
        if onboarding == nil {
            onboarding = OnboardingWindowController(
                onboarding: store.scope(state: \.onboarding, action: \.onboarding),
                remote: store.scope(state: \.remote, action: \.remote)
            )
        }
        onboarding?.show()
        settings?.close()
    }
}
