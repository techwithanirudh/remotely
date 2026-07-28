import SwiftUI

/// The steps, in order. Each one owns its own gate, so the container does not
/// need to know what any given step is waiting for.
enum OnboardingStepKind: Int, CaseIterable {
    case welcome
    case connect
    case permission
    case practice

    @MainActor
    func isSatisfied(by model: BridgeModel) -> Bool {
        switch self {
        case .welcome, .practice: true
        case .connect: model.connectionState == .running
        case .permission: model.accessibilityGranted
        }
    }
}

struct WelcomeStep: View {
    var body: some View {
        OnboardingStep(
            symbol: "av.remote.fill",
            title: "Control this Mac with your TV remote",
            detail: "Your remote's arrows move the pointer and Center clicks, over the "
                + "HDMI cable you already have. No extra hardware, no dongle."
        )
    }
}

struct ConnectStep: View {
    @ObservedObject var model: BridgeModel
    @Binding var brand: TVBrand

    var body: some View {
        OnboardingStep(
            symbol: "cable.connector",
            title: "Connect over HDMI",
            detail: "Three things have to be true before your remote reaches this Mac."
        ) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    OnboardingBullet(number: 1, text: "Plug this Mac into your TV with an HDMI cable.")
                    OnboardingBullet(number: 2, text: "Switch the TV to that HDMI input.")
                    OnboardingBullet(number: 3, text: "Turn on HDMI-CEC in the TV's settings.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                BrandPathCard(brand: $brand)

                OnboardingCheck(
                    done: model.connectionState == .running,
                    doneText: "Receiving remote buttons",
                    waitingText: "Waiting for the remote…"
                )
            }
        }
    }
}

struct PermissionStep: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        OnboardingStep(
            symbol: "lock.fill",
            title: "Allow Accessibility",
            detail: "macOS needs your permission before anything can move the pointer. "
                + "Without it the remote's buttons arrive but nothing happens."
        ) {
            VStack(spacing: 12) {
                OnboardingCheck(
                    done: model.accessibilityGranted,
                    doneText: "Permission allowed",
                    waitingText: "Not allowed yet"
                )

                if !model.accessibilityGranted {
                    Button("Open System Settings…") {
                        model.requestAccessibility()
                    }
                }
            }
        }
    }
}

/// Brand picker plus the literal menu path, since no maker calls it "HDMI-CEC".
struct BrandPathCard: View {
    @Binding var brand: TVBrand

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("My TV is a")
                    .font(.system(size: 12))

                Picker("", selection: $brand) {
                    ForEach(TVBrand.allCases) { Text($0.name).tag($0) }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 132)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Look for “\(brand.featureName)”")
                    .font(.system(size: 11.5, weight: .semibold))
                Text(brand.path)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: Theme.cornerRadius)
    }
}
