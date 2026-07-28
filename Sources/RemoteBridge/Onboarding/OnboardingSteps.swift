import SwiftUI

/// The steps, in order. Each one owns its own gate, so the container does not
/// need to know what any given step is waiting for.
enum OnboardingStepKind: Int, CaseIterable {
    case welcome
    case connect
    case permission
    case move
    case click
    case scroll

    @MainActor
    func isSatisfied(by model: BridgeModel) -> Bool {
        switch self {
        case .welcome, .move, .click, .scroll: true
        case .connect: model.connectionState == .running
        case .permission: model.accessibilityGranted
        }
    }
}

struct WelcomeStep: View {
    var body: some View {
        OnboardingStep(
            title: "Control this Mac with your TV remote",
            hint: "Over the HDMI cable you already have. No extra hardware, no dongle."
        ) {
            PermissionDialogMock(symbol: "av.remote.fill", tint: .accentColor)
        } accessory: {
            OnboardingIconRow(items: [
                .init(symbol: "arrow.up.and.down.and.arrow.left.and.right",
                      tint: .blue, label: "Move"),
                .init(symbol: "cursorarrow.click", tint: .purple, label: "Click"),
                .init(symbol: "arrow.up.and.down.text.horizontal",
                      tint: .teal, label: "Scroll"),
            ])
        }
    }
}

struct ConnectStep: View {
    @ObservedObject var model: BridgeModel
    @Binding var brand: TVBrand

    var body: some View {
        OnboardingStep(title: "Connect over HDMI") {
            PermissionDialogMock(symbol: "cable.connector", tint: .cyan, badge: "tv")
        } accessory: {
            VStack(spacing: 13) {
                VStack(alignment: .leading, spacing: 8) {
                    OnboardingBullet(number: 1, text: "Plug this Mac into your TV with HDMI.")
                    OnboardingBullet(number: 2, text: "Switch the TV to that input.")
                    OnboardingBullet(number: 3, text: "Turn on HDMI-CEC on the TV.")
                }

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
            title: "Remote Bridge needs your permission to move the pointer",
            hint: "Choose “Open System Settings”, then switch on Remote Bridge "
                + "under Accessibility."
        ) {
            PermissionDialogMock(symbol: "hand.raised.fill", tint: .orange, badge: "gearshape.fill")
        } accessory: {
            VStack(spacing: 11) {
                OnboardingCheck(
                    done: model.accessibilityGranted,
                    doneText: "Permission allowed",
                    waitingText: "Not allowed yet"
                )

                if !model.accessibilityGranted {
                    OnboardingButton(title: "Open System Settings") {
                        model.requestAccessibility()
                    }
                    .frame(width: 200)
                }
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
