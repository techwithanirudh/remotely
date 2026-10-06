import Combine
import ComposableArchitecture
import Defaults
import Foundation
import RemotelyKit

@MainActor
final class MenuBarCoordinator {
    private let statusItem: StatusItemController
    private var observers = Set<AnyCancellable>()

    init(store: StoreOf<AppFeature>) {
        statusItem = StatusItemController(
            onToggle: { store.send(.menu(.toggle)) },
            onSettings: { store.send(.menu(.settings)) },
            onCopyLog: { store.send(.menu(.copyLog)) },
            onCheckForUpdates: { store.send(.menu(.checkForUpdates)) },
            onQuit: { store.send(.menu(.quit)) }
        )

        Defaults.observe(.showsMenuBarIcon) { [weak self] change in
            self?.statusItem.isVisible = change.newValue
        }.tieToLifetime(of: self)

        store.publisher.remote
            .receive(on: RunLoop.main)
            .sink { [weak self] remote in
                self?.statusItem.update(status: remote.status, isEnabled: remote.isEnabled)
            }
            .store(in: &observers)
    }

    func start() {
        statusItem.isVisible = Defaults[.showsMenuBarIcon]
    }
}
