import AppKit
import RemoteKit
import SwiftUI

/// Picks what a button does.
///
/// The recorded shortcut rides on the menu item itself, the way Mac Mouse Fix
/// shows it: choosing "Keyboard Shortcut" starts listening, and what was
/// recorded reads back from the same control. One control on the row rather
/// than a picker and a field beside it.
struct ActionMenu: View {
    let binding: ButtonBinding
    let onPick: (RemoteAction) -> Void
    let onRecord: (KeyCombo) -> Void

    @State private var isArmed = false
    @State private var monitor: Any?

    var body: some View {
        Picker("", selection: Binding(get: { binding.action }, set: { choose($0) })) {
            ForEach(RemoteAction.Group.allCases, id: \.self) { group in
                Section {
                    ForEach(group.actions) { action in
                        Label(title(for: action), systemImage: action.symbol).tag(action)
                    }
                }
            }
        }
        .labelsHidden()
        .buttonStyle(.borderless)
        .fixedSize()
        .onDisappear(perform: disarm)
    }

    private func title(for action: RemoteAction) -> String {
        guard action == .keyboardShortcut else { return action.title }
        if isArmed { return "Type a shortcut…" }
        guard let combo = binding.combo else { return action.title }
        return "\(action.title)  \(combo.display)"
    }

    /// Picking Keyboard Shortcut has to commit the action as well as start
    /// listening. Only arming left the binding on its old action, so SwiftUI
    /// snapped the picker back and tore down the monitor before a key landed.
    private func choose(_ action: RemoteAction) {
        disarm()
        onPick(action)
        if action == .keyboardShortcut { arm() }
    }

    /// Swallows the keystroke while listening, so recording Command-W does not
    /// close the window. Escape cancels.
    private func arm() {
        guard !isArmed else { return }
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
