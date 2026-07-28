import SwiftUI

/// The steps, in order. Each one owns its own gate, so the container does not
/// need to know what any given step is waiting for.
enum OnboardingStepKind: Int, CaseIterable {
    case welcome
    case connect
    case permission
    case move
    case click
    case doubleClick
    case rightClick
    case scroll

    @MainActor
    func isSatisfied(by model: BridgeModel) -> Bool {
        switch self {
        case .welcome, .move, .click, .doubleClick, .rightClick, .scroll: true
        case .connect: model.connectionState == .running
        case .permission: model.accessibilityGranted
        }
    }

    /// Whether a blocked step can be moved past anyway. A TV that never reports
    /// CEC must not trap anyone, but skipping Accessibility would leave an app
    /// that cannot do the one thing it exists for.
    var isSkippable: Bool {
        switch self {
        case .permission: false
        default: true
        }
    }
}

/// Leads with the app icon and wordmark rather than a dialog mock, the way
/// Alcove's first screen does; there is no system prompt to preview yet.
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 76, height: 76)

            Text("Remote Bridge")
                .font(.system(size: 27, weight: .bold))
                .padding(.top, 2)

            Text("Your TV remote becomes a pointer for this Mac, "
                 + "over the HDMI cable you already have.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            OnboardingIconRow(items: [
                .init(symbol: "arrow.up.and.down.and.arrow.left.and.right",
                      tint: .blue, label: "Hold to\nmove"),
                .init(symbol: "cursorarrow.click", tint: .purple, label: "Center to\nclick"),
                .init(symbol: "arrow.up.and.down.text.horizontal",
                      tint: .teal, label: "Back twice\nto scroll"),
            ])
            .padding(.top, 20)

            Text("No extra hardware, no dongle, no subscription.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
        }
    }
}

struct ConnectStep: View {
    @ObservedObject var model: BridgeModel
    @Binding var brand: TVBrand

    var body: some View {
        // The numbered list said the same thing as the card below it, and the
        // status row said the same thing as the disabled button. Both are gone:
        // one line of instruction, one card, and the button reports the wait.
        OnboardingStep(
            title: "Connect over HDMI",
            hint: "Plug in the cable and switch the TV to that input, then turn on "
                + "HDMI-CEC in its settings."
        ) {
            PermissionDialogMock(symbol: "cable.connector", tint: .cyan, badge: "tv")
        } accessory: {
            BrandPathCard(brand: $brand)
        }
    }
}

struct PermissionStep: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        // The instruction only applies while permission is missing, and the
        // button below carries the action, so neither is repeated here.
        OnboardingStep(
            title: "Remote Bridge needs your permission to move the pointer",
            hint: model.accessibilityGranted
                ? nil
                : "Switch on Remote Bridge under Privacy & Security → Accessibility."
        ) {
            PermissionDialogMock(symbol: "hand.raised.fill", tint: .orange, badge: "gearshape.fill")
        } accessory: {
            if model.accessibilityGranted {
                OnboardingCheck(
                    done: true,
                    doneText: "Permission allowed",
                    waitingText: ""
                )
            }
        }
    }
}

/// Brand picker plus the literal menu path, since no maker calls it "HDMI-CEC".
struct BrandPathCard: View {
    @Binding var brand: TVBrand

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("My TV is a")
                    .font(.system(size: 11.5))

                Picker("", selection: $brand) {
                    ForEach(TVBrand.allCases) { Text($0.name).tag($0) }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 124)

                Spacer(minLength: 0)
            }

            Text("Look for “\(brand.featureName)”")
                .font(.system(size: 11, weight: .semibold))

            Text(brand.path)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: Theme.cornerRadius)
    }
}
