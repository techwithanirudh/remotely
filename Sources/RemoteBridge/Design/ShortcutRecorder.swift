import AppKit
import RemoteKit
import SwiftUI

/// Records the next combination the user presses.
///
/// Mac Mouse Fix pulls in MASShortcut for this; a local event monitor does the
/// same job without the dependency. While armed it swallows the keystroke, so
/// recording Command-W does not close the window.
struct ShortcutRecorder: View {
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
            // Modifiers on their own are not a shortcut; wait for a real key.
            guard event.type == .keyDown else { return nil }

            MainActor.assumeIsolated {
                // Escape cancels rather than being recorded.
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
