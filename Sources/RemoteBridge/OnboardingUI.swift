import SwiftUI

/// First-run flow.
///
/// Two things block the remote from working and neither is discoverable: the
/// TV has to be on the Mac's HDMI input with CEC enabled, and macOS has to
/// grant Accessibility. Both are checked live here, so the window reflects the
/// real state rather than asking the user to take it on faith.
struct OnboardingView: View {
    @ObservedObject var model: BridgeModel
    let onFinish: () -> Void

    private static let stepCount = 4

    @State private var step = 0
    @State private var brand: TVBrand = .samsung

    private var canContinue: Bool {
        switch step {
        case 1: model.connectionState == .running
        case 2: model.accessibilityGranted
        default: true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)

            HStack(spacing: 10) {
                ForEach(0..<Self.stepCount, id: \.self) { index in
                    Circle()
                        .fill(index == step ? Color.accentColor : Color.primary.opacity(0.16))
                        .frame(width: 6, height: 6)
                }

                Spacer()

                if step > 0 {
                    Button("Back") { step -= 1 }
                }

                // Never trap someone whose TV will not report CEC, or who wants
                // to grant permission later.
                if !canContinue {
                    Button(step == Self.stepCount - 1 ? "Skip" : "Skip for now") {
                        if step == Self.stepCount - 1 { onFinish() } else { step += 1 }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }

                Button(step == Self.stepCount - 1 ? "Done" : "Continue") {
                    if step == Self.stepCount - 1 {
                        onFinish()
                    } else {
                        step += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        // NSHostingController sizes the window to fit, which collapses this
        // to a strip without an explicit size.
        .frame(width: 540, height: 500)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            OnboardingStep(
                symbol: "av.remote.fill",
                title: "Control this Mac with your TV remote",
                detail: "Your remote's arrows move the pointer and Center clicks, over the "
                    + "HDMI cable you already have. No extra hardware, no dongle."
            )
        case 1:
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
        case 2:
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
        case 3:
            OnboardingStep(
                symbol: "hand.tap.fill",
                title: "Try it out",
                detail: "Drive these with the remote. They are real controls, so whatever "
                    + "works here works everywhere."
            ) {
                PracticeCard(model: model)
            }
        default:
            EmptyView()
        }
    }
}

/// A live practice area. These are ordinary SwiftUI controls, so the remote
/// drives them exactly as it drives the rest of the system — nothing here is
/// simulated, which is the point.
private struct PracticeCard: View {
    @ObservedObject var model: BridgeModel

    @State private var clicked: Set<Int> = []
    @State private var rightClicked = false

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Hold an arrow to glide over a dot, tap to fine-tune, then press Center",
                      systemImage: "cursorarrow.click")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { index in
                        Button {
                            clicked.insert(index)
                        } label: {
                            Circle()
                                .fill(clicked.contains(index) ? Color.green : Color.primary.opacity(0.13))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if clicked.contains(index) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Right click works") { rightClicked = true }
                        }
                    }

                    Spacer()

                    Text("\(clicked.count)/3")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(clicked.count == 3 ? .green : .secondary)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: Theme.cornerRadius)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Press Back twice, then hold an arrow to scroll",
                          systemImage: "arrow.up.and.down.text.horizontal")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if model.scrollMode {
                        Text("Scrolling")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 7)
                            .frame(height: 18)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(1...14, id: \.self) { row in
                            Text("Scrollable line \(row)")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 74)
                .cardSurface(cornerRadius: 8)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: Theme.cornerRadius)
        }
    }
}

private struct OnboardingStep<Accessory: View>: View {
    let symbol: String
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    init(
        symbol: String,
        title: String,
        detail: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    Color.accentColor,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .multilineTextAlignment(.center)

            Text(detail)
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            accessory
                .padding(.top, 4)

            Spacer()
        }
    }
}

/// Brand picker plus the literal menu path for that brand.
private struct BrandPathCard: View {
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
                .frame(width: 130)

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

private struct OnboardingBullet: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 17, height: 17)
                .background(Color.accentColor, in: Circle())

            Text(text)
                .font(.system(size: 12.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingCheck: View {
    let done: Bool
    let doneText: String
    let waitingText: String

    var body: some View {
        HStack(spacing: 7) {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ProgressView().controlSize(.small)
            }

            Text(done ? doneText : waitingText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(done ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .cardSurface(cornerRadius: Theme.cornerRadius)
    }
}
