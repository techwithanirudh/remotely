import SwiftUI
import RemoteCore

struct ControlsSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .controls) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Make the remote yours")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Assign any macOS action to each remote button.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Reset Defaults") {
                        model.resetMappings()
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 11)

                SectionLabel(title: "How to use the remote")
                    .padding(.top, 0)

                SettingsCard {
                    GestureGuideRow(
                        symbol: "hand.tap",
                        title: "Tap an arrow",
                        detail: "Nudges the pointer a few pixels, for hitting a small target."
                    )
                    CardDivider()
                    GestureGuideRow(
                        symbol: "hand.point.up.left.and.text",
                        title: "Hold an arrow",
                        detail: "Glides the pointer, speeding up the longer you hold."
                    )
                    CardDivider()
                    GestureGuideRow(
                        symbol: "cursorarrow.click",
                        title: "Press Center",
                        detail: "Clicks. Press twice to double-click, hold for a right click."
                    )
                    CardDivider()
                    GestureGuideRow(
                        symbol: "arrow.up.and.down.text.horizontal",
                        title: "Press Back twice",
                        detail: "Switches the arrows between moving the pointer and scrolling.",
                        highlighted: model.scrollMode,
                        badge: model.scrollMode ? "Scrolling" : nil
                    )
                }

                SectionLabel(title: "Pointer")

                SettingsCard {
                    MappingEditorRow(button: .up, model: model)
                    CardDivider()
                    MappingEditorRow(button: .down, model: model)
                    CardDivider()
                    MappingEditorRow(button: .left, model: model)
                    CardDivider()
                    MappingEditorRow(button: .right, model: model)
                }

                SectionLabel(title: "Center")

                SettingsCard {
                    MappingEditorRow(button: .center, model: model)
                    CardDivider()
                    MappingEditorRow(button: .centerDouble, model: model)
                    CardDivider()
                    MappingEditorRow(button: .centerHold, model: model)
                }

                SectionLabel(title: "Back")

                SettingsCard {
                    MappingEditorRow(button: .back, model: model)
                    CardDivider()
                    MappingEditorRow(button: .doubleBack, model: model)
                }

                Label(
                    "Volume, media and Home never reach the Mac. Displays handle those "
                        + "themselves and never put them on the CEC bus.",
                    systemImage: "info.circle"
                )
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.top, 10)
            }
        }
    }
}

struct GestureGuideRow: View {
    let symbol: String
    let title: String
    let detail: String
    var highlighted = false
    var badge: String?

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(highlighted ? Color.accentColor : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Color.accentColor.opacity(0.14), in: Capsule())
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
    }
}

struct MappingEditorRow: View {
    let button: RemoteButton
    @ObservedObject var model: BridgeModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: button.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: 22)

            Text(button.title)
                .font(.system(size: 13))

            Spacer(minLength: 8)

            // Reset sits before the picker, in a slot that is always reserved.
            // Trailing it pushed the picker off the edge every other card's
            // controls line up on, and inserting it only when needed made that
            // row's picker jump sideways.
            Button {
                model.resetAction(for: button)
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reset to default")
            .opacity(model.isDefaultAction(for: button) ? 0 : 1)
            .disabled(model.isDefaultAction(for: button))
            .frame(width: 14)

            Picker("", selection: Binding(
                get: { model.action(for: button) },
                set: { model.setAction($0, for: button) }
            )) {
                ForEach(MacAction.allCases) { action in
                    Label(action.title, systemImage: action.symbol)
                        .tag(action)
                }
            }
            .labelsHidden()
            .controlSize(.small)
            .frame(width: 178)
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(height: 43)
    }
}
