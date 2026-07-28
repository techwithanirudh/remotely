import Defaults
import RemoteKit
import SwiftUI

/// The steps, in order. Each owns its own gate, so the container never needs to
/// know what a given step is waiting for.
enum Step: Int, CaseIterable {
    case welcome, connect, permission
    case move, click, doubleClick, rightClick, scroll
    case finish

    @MainActor
    func isSatisfied(by bridge: RemoteBridge) -> Bool {
        switch self {
        case .connect: bridge.status.isReady || bridge.status == .needsPermission
        case .permission: bridge.hasAccessibility
        default: true
        }
    }

    /// Whether the step can ever block. Only these reserve room for a skip;
    /// the rest would leave dead space under the button for a control that
    /// can never appear.
    var isGated: Bool {
        switch self {
        case .connect, .permission: true
        default: false
        }
    }

    /// A TV that never reports CEC must not trap anyone, but skipping
    /// Accessibility leaves an app that cannot do the one thing it exists for.
    var isSkippable: Bool { self != .permission }
}

/// First-run flow.
///
/// Nothing about the setup is discoverable, and getting either half wrong looks
/// exactly like a broken remote, so every step checks real state. Laid out as a
/// borderless portrait panel, which is also why nothing has to line up with
/// window buttons.
struct OnboardingView: View {
    @ObservedObject var bridge: RemoteBridge
    let onFinish: () -> Void

    static let panelSize = CGSize(width: 330, height: 560)

    @Default(.onboardingStep) private var rawStep
    @Default(.tvBrand) private var brand

    private var step: Step { Step(rawValue: rawStep) ?? .welcome }
    private var isLast: Bool { step == Step.allCases.last }
    private var canContinue: Bool { step.isSatisfied(by: bridge) }

    var body: some View {
        ZStack {
            Vibrancy(material: .popover)

            VStack(spacing: 0) {
                header

                // Slack goes above the content rather than being split with the
                // space below it. Splitting it evenly left a short step with a
                // large gap over the button as well as under the header.
                Spacer(minLength: 12)
                content.frame(maxWidth: .infinity)
                Spacer(minLength: 12).frame(maxHeight: 26)

                footer
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.panelRadius, style: .continuous))
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

    /// Back and progress live up here, so the bottom is just the action.
    private var header: some View {
        ZStack {
            HStack(spacing: 5) {
                ForEach(Step.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item == step ? Color.primary.opacity(0.45) : Color.primary.opacity(0.14))
                        .frame(width: item == step ? 14 : 5, height: 5)
                        .animation(.easeOut(duration: 0.18), value: step)
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

    /// A blocked step reports why on the button itself, and offers the action
    /// that unblocks it where one exists.
    private var primaryTitle: String {
        switch step {
        case .connect where !canContinue: "Waiting for the remote…"
        case .permission where !canContinue: "Open System Settings"
        default: isLast ? "Done" : "Continue"
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            PanelButton(
                title: primaryTitle,
                isWaiting: step == .connect && !canContinue,
                action: runPrimary
            )

            if step.isGated, step.isSkippable {
                Button("Skip for now", action: advance)
                    .buttonStyle(.plain)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .opacity(canContinue ? 0 : 1)
                    .disabled(canContinue)
                    .frame(height: 16)
            }
        }
    }

    private func runPrimary() {
        if step == .permission, !canContinue {
            bridge.requestPermission()
        } else {
            advance()
        }
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            onFinish()
            return
        }
        rawStep = next.rawValue
    }

    private func back() {
        rawStep = max(0, step.rawValue - 1)
    }
}
