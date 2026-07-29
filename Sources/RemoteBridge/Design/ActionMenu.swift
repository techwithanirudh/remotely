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
            content.frame(minWidth: 76, minHeight: 22, alignment: .trailing)
        }
        .buttonStyle(.plain)
        .onAppear { if combo == nil { arm() } }
        .onDisappear(perform: disarm)
    }

    @ViewBuilder
    private var content: some View {
        if isArmed {
            prompt("Type a shortcut", tint: Color.accentColor)
        } else if let combo {
            HStack(spacing: 3) {
                ForEach(Array(caps(of: combo).enumerated()), id: \.offset) { _, cap in
                    KeyCap(text: cap)
                }
            }
        } else {
            prompt("Not set", tint: HierarchicalShapeStyle.secondary)
        }
    }

    private func prompt(_ text: String, tint: some ShapeStyle) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(
                isArmed ? Color.accentColor.opacity(0.14) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isArmed ? Color.accentColor.opacity(0.55) : Theme.cardStroke)
            }
    }

    /// Modifier glyphs first, then whatever names the key.
    private func caps(of combo: KeyCombo) -> [String] {
        let modifiers: Set<Character> = ["⌃", "⌥", "⇧", "⌘"]
        var caps: [String] = []
        var key = ""

        for character in combo.display {
            if modifiers.contains(character), key.isEmpty {
                caps.append(String(character))
            } else {
                key.append(character)
            }
        }
        if !key.isEmpty { caps.append(key) }
        return caps
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

/// One key drawn as a cap, the way System Settings shows a shortcut.
private struct KeyCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, text.count > 1 ? 6 : 0)
            .frame(minWidth: 21, minHeight: 21)
            .background(Theme.cardFill, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Theme.cardStroke)
            }
    }
}
