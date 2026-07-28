import SwiftUI

/// First-run flow.
///
/// Nothing about the setup is discoverable: the TV has to be on the Mac's HDMI
/// input with CEC switched on, and macOS has to grant Accessibility. Getting
/// either wrong looks exactly like a broken remote, so each step checks the real
/// state rather than asking the user to take it on faith.
///
/// Laid out as a borderless portrait panel like Alcove's, which is also why it
/// has no window buttons to align against.
struct OnboardingView: View {
    @ObservedObject var model: BridgeModel
    let onFinish: () -> Void

    static let panelSize = CGSize(width: 330, height: 560)

    /// Persisted so quitting mid-flow resumes where it left off. Granting
    /// Accessibility often means relaunching, which would otherwise throw the
    /// user back to the welcome screen every time.
    @AppStorage(OnboardingProgress.stepKey) private var storedStep = 0
    @AppStorage(OnboardingProgress.brandKey) private var storedBrand = TVBrand.samsung.rawValue

    private var step: OnboardingStepKind {
        OnboardingStepKind(rawValue: storedStep) ?? .welcome
    }

    private var brand: Binding<TVBrand> {
        Binding(
            get: { TVBrand(rawValue: storedBrand) ?? .samsung },
            set: { storedBrand = $0.rawValue }
        )
    }

    private var steps: [OnboardingStepKind] { OnboardingStepKind.allCases }
    private var isLast: Bool { step == steps.last }
    private var canContinue: Bool { step.isSatisfied(by: model) }

    var body: some View {
        ZStack {
            VisualEffectPanel()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 10)

                content
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 10)

                footer
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .connect: ConnectStep(model: model, brand: brand)
        case .permission: PermissionStep(model: model)
        case .move: MoveStep()
        case .click: ClickStep()
        case .doubleClick: DoubleClickStep()
        case .rightClick: RightClickStep()
        case .scroll: ScrollStep(model: model)
        case .finish: FinishStep(model: model)
        }
    }

    /// Back and progress live up here so the bottom is just the action, the way
    /// Alcove's is. Crowding them onto one footer row read as clutter.
    private var header: some View {
        ZStack {
            HStack(spacing: 5) {
                ForEach(steps, id: \.self) { item in
                    Capsule()
                        .fill(item == step
                              ? Color.primary.opacity(0.45)
                              : Color.primary.opacity(0.14))
                        .frame(width: item == step ? 14 : 5, height: 5)
                        .animation(.easeOut(duration: 0.18), value: step)
                }
            }

            HStack {
                if step != .welcome {
                    Button(action: goBack) {
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

    /// A blocked step reports why on the button rather than in a status row
    /// above it, and offers the action that unblocks it where one exists.
    private var primaryTitle: String {
        switch step {
        case .connect where !canContinue: "Waiting for the remote…"
        case .permission where !canContinue: "Open System Settings"
        default: isLast ? "Done" : "Continue"
        }
    }

    private func runPrimary() {
        if step == .permission, !canContinue {
            model.requestAccessibility()
            return
        }
        advance()
    }

    private var footer: some View {
        VStack(spacing: 8) {
            OnboardingButton(
                title: primaryTitle,
                waiting: step == .connect && !canContinue,
                action: runPrimary
            )

            // Never trap someone whose TV will not report CEC. Accessibility
            // has no skip: without it nothing the app does works.
            Button("Skip for now", action: advance)
                .buttonStyle(.plain)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .opacity(canContinue || !step.isSkippable ? 0 : 1)
                .disabled(canContinue || !step.isSkippable)
                .frame(height: 16)
        }
    }

    private func advance() {
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else {
            onFinish()
            return
        }
        storedStep = steps[index + 1].rawValue
    }

    private func goBack() {
        guard let index = steps.firstIndex(of: step), index > 0 else { return }
        storedStep = steps[index - 1].rawValue
    }
}

private struct VisualEffectPanel: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        // `.underWindowBackground` has nothing to sit under in a borderless
        // floating panel and renders flat grey; `.popover` actually blurs
        // what is behind the window.
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
