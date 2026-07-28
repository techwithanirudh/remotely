import SwiftUI
import AppKit

/// Records the next key combination the user presses.
///
/// Mac Mouse Fix uses MASShortcut for this; the job is small enough that a
/// local event monitor does it without the dependency. While armed it swallows
/// the keystroke so recording ⌘W does not close the window.
struct ShortcutRecorder: View {
    let shortcut: KeyboardShortcut?
    let onRecord: (KeyboardShortcut) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            isRecording ? stop() : start()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: isRecording ? .default : .rounded))
                .foregroundStyle(isRecording ? Color.accentColor : .primary)
                .frame(minWidth: 74)
                .frame(height: 20)
                .padding(.horizontal, 8)
                .background(
                    isRecording ? Color.accentColor.opacity(0.15) : Theme.selectionFill,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isRecording ? Color.accentColor.opacity(0.5) : .clear)
                }
        }
        .buttonStyle(.plain)
        .help(isRecording ? "Press a key combination" : "Click to record a shortcut")
        .onDisappear(perform: stop)
    }

    private var label: String {
        if isRecording { return "Press keys…" }
        return shortcut?.display ?? "Record"
    }

    private func start() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            // Modifiers alone are not a shortcut; wait for a real key.
            guard event.type == .keyDown else { return nil }

            if let recorded = KeyboardShortcut(event: event), event.keyCode != 53 {
                MainActor.assumeIsolated { onRecord(recorded) }
            }
            MainActor.assumeIsolated { stop() }
            return nil
        }
    }

    private func stop() {
        isRecording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
