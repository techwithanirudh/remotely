import AppKit
import RemoteKit
import SwiftUI

/// Picks what a button does, with the shortcut recorder beside it.
///
/// A Menu with grouped sections was tried here and half its items did not
/// register, so this stays on Picker, which does.
struct ActionMenu: View {
    let binding: ButtonBinding
    let onPick: (RemoteAction) -> Void
    let onRecord: (KeyCombo) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: Binding(get: { binding.action }, set: onPick)) {
                ForEach(RemoteAction.allCases) { action in
                    Label(action.title, systemImage: action.symbol).tag(action)
                }
            }
            .labelsHidden()
            .controlSize(.small)
            .frame(width: 178)

            if binding.action == .keyboardShortcut {
                ShortcutField(combo: binding.combo, onRecord: onRecord)
            }
        }
    }
}

/// Captures the next combination pressed.
///
/// Choosing Keyboard Shortcut arms it straight away, the way Mac Mouse Fix does:
/// there is nothing else to do at that point, so a separate Record button was
/// only ever a second click. Clicking an existing shortcut re-arms it. While
/// armed it swallows the keystroke, so recording Command-W does not close the
/// window, and Escape cancels.
private struct ShortcutField: View {
    let combo: KeyCombo?
    let onRecord: (KeyCombo) -> Void

    @State private var isArmed = false
    @State private var monitor: Any?

    var body: some View {
        Button { isArmed ? disarm() : arm() } label: {
            Text(isArmed ? "Type a shortcut" : combo?.display ?? "Not set")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(label)
                .frame(minWidth: 74, minHeight: 20)
                .padding(.horizontal, 8)
                .background(
                    isArmed ? Color.accentColor.opacity(0.15) : Theme.selection,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isArmed ? Color.accentColor.opacity(0.5) : .clear)
                }
        }
        .buttonStyle(.plain)
        .onAppear { if combo == nil { arm() } }
        .onDisappear(perform: disarm)
    }

    private var label: some ShapeStyle {
        if isArmed { return AnyShapeStyle(Color.accentColor) }
        return combo == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)
    }

    private func arm() {
        isArmed = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard event.type == .keyDown else { return nil }

            MainActor.assumeIsolated {
                if event.keyCode != 53, let flags = event.cgEvent?.flags {
                    onRecord(KeyCombo(keyCode: event.keyCode, modifiers: flags))
                }
                disarm()
            }
            return nil
        }
    }

    private func disarm() {
        isArmed = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
