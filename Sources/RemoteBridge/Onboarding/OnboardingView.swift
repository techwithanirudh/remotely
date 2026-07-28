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

    @State private var step: OnboardingStepKind = .welcome
    @State private var brand: TVBrand = .samsung

    private var steps: [OnboardingStepKind] { OnboardingStepKind.allCases }
    private var isLast: Bool { step == steps.last }
    private var canContinue: Bool { step.isSatisfied(by: model) }

    var body: some View {
        ZStack {
            VisualEffectPanel()

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                content
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 12)

                footer
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .connect: ConnectStep(model: model, brand: $brand)
        case .permission: PermissionStep(model: model)
        case .practice: PracticeStep(model: model)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            OnboardingButton(title: isLast ? "Done" : "Continue", action: advance)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.45)

            HStack(spacing: 10) {
                if step != .welcome {
                    Button("Back", action: goBack)
                        .buttonStyle(.plain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }

                ForEach(steps, id: \.self) { item in
                    Circle()
                        .fill(item == step ? Color.primary.opacity(0.55) : Color.primary.opacity(0.16))
                        .frame(width: 5, height: 5)
                }

                // Never trap someone whose TV will not report CEC, or who wants
                // to grant permission later.
                if !canContinue {
                    Button(isLast ? "Skip" : "Skip for now", action: advance)
                        .buttonStyle(.plain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func advance() {
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else {
            onFinish()
            return
        }
        step = steps[index + 1]
    }

    private func goBack() {
        guard let index = steps.firstIndex(of: step), index > 0 else { return }
        step = steps[index - 1]
    }
}

private struct VisualEffectPanel: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
