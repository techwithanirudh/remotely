import Combine
import ComposableArchitecture

@MainActor
final class RemoteOverlayCoordinator {
    private let overlay = ScrollModeOverlay()
    private var observer: AnyCancellable?

    init(store: StoreOf<AppFeature>) {
        observer = store.publisher.remote
            .sink { [weak self] remote in
                self?.overlay.setVisible(remote.isScrolling)
            }
    }

    func start() {
        overlay.setVisible(false)
    }
}
