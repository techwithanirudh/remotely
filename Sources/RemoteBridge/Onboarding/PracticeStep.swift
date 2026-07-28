import SwiftUI

/// The practice steps.
///
/// One action per screen rather than a single crowded panel: each is a real
/// SwiftUI control, so the remote drives it exactly as it drives the rest of the
/// system. Nothing here is simulated, which is the point.

/// Aim the pointer at a target and hit it.
struct MoveStep: View {
    @State private var reached = false

    var body: some View {
        OnboardingStep(
            title: "Hold an arrow to move the pointer",
            hint: reached
                ? "That is the whole trick: hold to travel, tap to fine-tune."
                : "Holding speeds up the longer you hold. A quick tap nudges a few pixels."
        ) {
            PermissionDialogMock(symbol: "arrow.up.and.down.and.arrow.left.and.right",
                                 tint: .blue)
        } accessory: {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Color.clear)

                Circle()
                    .fill(reached ? Color.green : Color.primary.opacity(0.13))
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: reached ? "checkmark" : "scope")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(reached ? .white : .secondary)
                    }
                    .onHover { if $0 { reached = true } }
            }
            .frame(height: 74)
            .frame(maxWidth: .infinity)
            .cardSurface(cornerRadius: Theme.cardCornerRadius)
        }
    }
}

/// Click three targets with Center.
struct ClickStep: View {
    @State private var clicked: Set<Int> = []

    var body: some View {
        OnboardingStep(
            title: "Press Center to click",
            hint: clicked.count == 3
                ? "Press twice quickly to double-click, hold for a right click."
                : "Move onto a dot, then press Center."
        ) {
            PermissionDialogMock(symbol: "cursorarrow.click", tint: .purple)
        } accessory: {
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { index in
                    Button {
                        clicked.insert(index)
                    } label: {
                        Circle()
                            .fill(clicked.contains(index)
                                  ? Color.green
                                  : Color.primary.opacity(0.13))
                            .frame(width: 32, height: 32)
                            .overlay {
                                if clicked.contains(index) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 74)
            .frame(maxWidth: .infinity)
            .cardSurface(cornerRadius: Theme.cardCornerRadius)
        }
    }
}

/// Switch to scroll mode and move a list.
struct ScrollStep: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        OnboardingStep(
            title: "Press Back twice to scroll",
            hint: model.scrollMode
                ? "Scrolling is on. Press Back twice again to go back to moving."
                : "That switches the arrows between moving the pointer and scrolling."
        ) {
            PermissionDialogMock(symbol: "arrow.up.and.down.text.horizontal", tint: .teal)
        } accessory: {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(1...16, id: \.self) { row in
                        Text("Scrollable line \(row)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 74)
            .cardSurface(cornerRadius: Theme.cardCornerRadius)
        }
    }
}
