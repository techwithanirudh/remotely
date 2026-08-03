import ComposableArchitecture
import Defaults
import RemotelyKit
import SwiftUI

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var step: OnboardingStep = .init(rawValue: Defaults[.onboardingStep]) ?? .welcome
        var brand: TVBrand = Defaults[.tvBrand]
        var connectBaseline: UInt64?
    }

    enum Action: Equatable {
        case back
        case bindingBrand(TVBrand)
        case next
        case requestPermission
        case reset
        case stepAppeared(pressCount: UInt64)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case finished
        }
    }

    @Dependency(\.remoteClient) var remoteClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .back:
                state.step = OnboardingStep(rawValue: max(0, state.step.rawValue - 1)) ?? .welcome
                Defaults[.onboardingStep] = state.step.rawValue
                return .none

            case let .bindingBrand(brand):
                state.brand = brand
                Defaults[.tvBrand] = brand
                return .none

            case .next:
                guard let next = OnboardingStep(rawValue: state.step.rawValue + 1) else {
                    return .send(.delegate(.finished))
                }
                state.step = next
                Defaults[.onboardingStep] = next.rawValue
                return .none

            case .requestPermission:
                return .run { _ in await remoteClient.requestPermission() }

            case .reset:
                state.step = .welcome
                state.brand = .samsung
                state.connectBaseline = nil
                Defaults[.onboardingStep] = state.step.rawValue
                Defaults[.tvBrand] = state.brand
                return .none

            case let .stepAppeared(pressCount):
                state.connectBaseline = state.step == .connect ? pressCount : nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    let remote: StoreOf<RemoteFeature>

    private var step: OnboardingStep { store.step }
    private var isLast: Bool { step == OnboardingStep.allCases.last }
    private var canGo: Bool {
        if step == .connect {
            guard let baseline = store.connectBaseline else { return false }
            return remote.pressCount > baseline
        }
        return step.isSatisfied(hasAccessibility: remote.hasAccessibility)
    }

    var body: some View {
        ZStack {
            Vibrancy(material: .popover)

            VStack(spacing: 0) {
                header

                Spacer(minLength: 12)
                content.frame(maxWidth: .infinity)
                Spacer(minLength: 12)

                footer
            }
            .padding(.horizontal, Theme.Onboarding.insetX)
            .padding(.vertical, Theme.Onboarding.insetY)
        }
        .frame(width: Theme.Onboarding.size.width, height: Theme.Onboarding.size.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Panel.radius, style: .continuous))
        .onAppear { store.send(.stepAppeared(pressCount: remote.pressCount)) }
        .onChange(of: step) { _, _ in
            store.send(.stepAppeared(pressCount: remote.pressCount))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .connect:
            ConnectStep(brand: Binding(
                get: { store.brand },
                set: { store.send(.bindingBrand($0)) }
            ))
        case .permission: PermissionStep(remote: remote)
        case .move: PracticeStep(.move)
        case .click: PracticeStep(.click)
        case .doubleClick: PracticeStep(.doubleClick)
        case .rightClick: PracticeStep(.rightClick)
        case .scroll: PracticeStep(.scroll, isScrolling: remote.isScrolling)
        case .finish: FinishStep()
        }
    }

    private var header: some View {
        ZStack {
            HStack(spacing: 5) {
                ForEach(OnboardingStep.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item == step ? Color.primary.opacity(0.45) : Color.primary
                            .opacity(0.14))
                        .frame(width: item == step ? 14 : 5, height: 5)
                        .animation(Theme.Motion.state, value: step)
                }
            }

            HStack {
                if step != .welcome {
                    Button { store.send(.back) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .frame(height: 22)
    }

    private var primaryTitle: String {
        switch step {
        case .connect where !canGo: "Waiting for the remote…"
        case .permission where !canGo: "Open System Settings"
        default: isLast ? "Done" : "Continue"
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            PanelButton(
                title: primaryTitle,
                isWaiting: step == .connect && !canGo,
                action: runPrimary
            )

            if step.isSkippable, !canGo {
                Button("Skip") { store.send(.next) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private func runPrimary() {
        if isLast {
            store.send(.next)
        } else if step == .permission, !canGo {
            store.send(.requestPermission)
        } else {
            store.send(.next)
        }
    }
}
