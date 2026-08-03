import AppKit
import RemotelyKit
import SwiftUI

struct ActionMenu: View {
    let binding: ButtonBinding
    let onPick: (RemoteAction) -> Void
    let onRecord: (KeyCombo) -> Void

    @State private var isArmed = false
    @State private var monitor: Any?

    var body: some View {
        Select(selection: Binding(get: { binding.action }, set: { choose($0) })) {
            ForEach(RemoteAction.Group.allCases, id: \.self) { group in
                Section {
                    ForEach(group.actions) { action in
                        Label(title(for: action), systemImage: action.symbol).tag(action)
                    }
                }
            }
        }
        .onDisappear(perform: disarm)
    }

    private func title(for action: RemoteAction) -> String {
        guard action == .keyboardShortcut else { return action.title }
        if isArmed { return "Type a shortcut…" }
        guard let combo = binding.combo else { return action.title }
        return "\(action.title)  \(combo.display)"
    }

    private func choose(_ action: RemoteAction) {
        disarm()
        onPick(action)
        if action == .keyboardShortcut { arm() }
    }

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
