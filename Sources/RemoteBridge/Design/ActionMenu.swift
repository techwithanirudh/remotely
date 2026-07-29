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
/// While armed it swallows the keystroke, so recording Command-W does not close
/// the window. Escape cancels rather than being captured.
private struct ShortcutField: View {
    let combo: KeyCombo?
    let onRecord: (KeyCombo) -> Void

    @State private var isArmed = false
    @State private var monitor: Any?

    var body: some View {
        Button { isArmed ? disarm() : arm() } label: {
            Text(isArmed ? "Press keys…" : combo?.display ?? "Record")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isArmed ? Color.accentColor : .primary)
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
        .help(isArmed ? "Press a key combination" : "Click to record a shortcut")
        .onDisappear(perform: disarm)
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
