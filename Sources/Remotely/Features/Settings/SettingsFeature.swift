import ComposableArchitecture
import Defaults
import Foundation
import RemotelyKit
import SwiftUI

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var page: SettingsPage = .general
        var canCheckForUpdates = false
        var lastUpdateCheck: Date?
        var checksAutomatically = true
        var installsAutomatically = false
        var channel: ReleaseChannel = Defaults[.releaseChannel]
        var availableVersion: String?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case checkForUpdates
        case delegate(Delegate)
        case onAppear
        case availabilityChanged(String?)
        case selectPage(SettingsPage)
        case update(UpdateClient.Snapshot)

        enum Delegate: Equatable {
            case factoryReset
            case replayOnboarding
        }
    }

    private enum CancelID {
        case availability
    }

    @Dependency(\.updateClient) var updateClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.checksAutomatically):
                let value = state.checksAutomatically
                return .run { _ in await updateClient.setChecksAutomatically(value) }

            case .binding(\.installsAutomatically):
                let value = state.installsAutomatically
                return .run { _ in await updateClient.setInstallsAutomatically(value) }

            case .binding(\.channel):
                let channel = state.channel
                return .run { _ in await updateClient.setChannel(channel) }

            case .binding:
                return .none

            case .checkForUpdates:
                return .run { _ in await updateClient.checkForUpdates() }

            case .delegate:
                return .none

            case .onAppear:
                return .merge(
                    .run { send in
                        let snapshot = await updateClient.snapshot()
                        await send(.update(snapshot))
                        if snapshot.checksAutomatically, snapshot.availableVersion == nil {
                            await updateClient.probe()
                        }
                    },
                    .run { send in
                        for await version in await updateClient.availability() {
                            await send(.availabilityChanged(version))
                        }
                    }
                    .cancellable(id: CancelID.availability, cancelInFlight: true)
                )

            case let .availabilityChanged(version):
                state.availableVersion = version
                return .run { send in await send(.update(updateClient.snapshot())) }

            case let .update(snapshot):
                state.canCheckForUpdates = snapshot.canCheck
                state.lastUpdateCheck = snapshot.lastCheck
                state.checksAutomatically = snapshot.checksAutomatically
                state.installsAutomatically = snapshot.installsAutomatically
                state.channel = snapshot.channel
                state.availableVersion = snapshot.availableVersion
                return .none

            case let .selectPage(page):
                state.page = page
                return .none
            }
        }
    }
}

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    let remote: StoreOf<RemoteFeature>
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        ZStack {
            if activeState == .inactive {
                Color(nsColor: .windowBackgroundColor)
                Vibrancy(blendingMode: .withinWindow)
            } else {
                Vibrancy()
            }

            HStack(spacing: 0) {
                Sidebar(store: store, remote: remote)
                    .frame(width: Theme.Sidebar.width)

                Rectangle()
                    .fill(Theme.Color.divider)
                    .frame(width: 1)

                store.page.pane(settings: store, remote: remote)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(WindowEdgeHighlight())
        .frame(minWidth: 660, minHeight: 600)
        .ignoresSafeArea()
        .onAppear { store.send(.onAppear) }
    }
}
