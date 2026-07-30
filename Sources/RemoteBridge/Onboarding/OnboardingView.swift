import Defaults
import RemoteKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var bridge: RemoteBridge
    let onFinish: () -> Void

    @Default(.onboardingStep) private var rawStep
    @Default(.tvBrand) private var brand

    private var step: OnboardingStep { OnboardingStep(rawValue: rawStep) ?? .welcome }
    private var isLast: Bool { step == OnboardingStep.allCases.last }
    private var canGo: Bool { step.isSatisfied(by: bridge) }

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
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .connect: ConnectStep(brand: $brand)
        case .permission: PermissionStep(bridge: bridge)
        case .move: PracticeStep(.move)
        case .click: PracticeStep(.click)
        case .doubleClick: PracticeStep(.doubleClick)
        case .rightClick: PracticeStep(.rightClick)
        case .scroll: PracticeStep(.scroll, isScrolling: bridge.isScrolling)
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
                    Button(action: back) {
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
                Button("Skip", action: advance)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private func runPrimary() {
        if step == .permission, !canGo {
            bridge.requestPermission()
        } else {
            advance()
        }
    }

    private func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else {
            onFinish()
            return
        }
        rawStep = next.rawValue
    }

    private func back() {
        rawStep = max(0, step.rawValue - 1)
    }
}
