import SwiftUI

/// First-run flow.
///
/// Nothing about the setup is discoverable: the TV has to be on the Mac's HDMI
/// input with CEC switched on, and macOS has to grant Accessibility. Getting
/// either wrong looks exactly like a broken remote, so each step checks the real
/// state rather than asking the user to take it on faith.
struct OnboardingView: View {
    @ObservedObject var model: BridgeModel
    let onFinish: () -> Void

    @State private var step: OnboardingStepKind = .welcome
    @State private var brand: TVBrand = .samsung

    private var steps: [OnboardingStepKind] { OnboardingStepKind.allCases }
    private var isLast: Bool { step == steps.last }
    private var canContinue: Bool { step.isSatisfied(by: model) }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 36)

            footer
        }
        // NSHostingController sizes the window to fit, which collapses this to a
        // strip without an explicit size.
        .frame(width: 540, height: 500)
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
        HStack(spacing: 10) {
            ForEach(steps, id: \.self) { item in
                Circle()
                    .fill(item == step ? Color.accentColor : Color.primary.opacity(0.16))
                    .frame(width: 6, height: 6)
            }

            Spacer()

            if step != .welcome {
                Button("Back", action: goBack)
            }

            // Never trap someone whose TV will not report CEC, or who wants to
            // grant permission later.
            if !canContinue {
                Button(isLast ? "Skip" : "Skip for now", action: advance)
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Button(isLast ? "Done" : "Continue", action: advance)
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
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
