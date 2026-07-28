import AppKit
import RemoteKit
import SwiftUI

/// Picks what a button does.
///
/// Modelled on Mac Mouse Fix: "Keyboard Shortcut…" lives in the menu itself and
/// the recorded combination becomes the shown value, rather than a separate
/// record control sitting beside the picker. One control, and the row reads as
/// the answer to "what does this button do".
struct ActionMenu: View {
    let binding: ButtonBinding
    let onPick: (RemoteAction) -> Void
    let onRecord: (KeyCombo) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?

    private static let grouped: [[RemoteAction]] = [
        [.none],
        [.moveUp, .moveDown, .moveLeft, .moveRight],
        [.scrollUp, .scrollDown, .scrollLeft, .scrollRight, .toggleScrolling],
        [.leftClick, .doubleClick, .rightClick],
        [.escape, .showDesktop, .missionControl],
    ]

    var body: some View {
        Menu {
            ForEach(Array(Self.grouped.enumerated()), id: \.offset) { _, group in
                Section {
                    ForEach(group) { action in
                        Button {
                            onPick(action)
                        } label: {
                            Label(action.title, systemImage: action.symbol)
                        }
                    }
                }
            }

            Section {
                Button("Keyboard Shortcut…") { arm() }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isRecording ? "record.circle" : binding.action.symbol)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: isRecording ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(isRecording ? Color.accentColor : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .frame(width: 186)
        .onDisappear(perform: disarm)
    }

    private var label: String {
        isRecording ? "Press keys…" : binding.summary
    }

    /// Swallows the keystroke while armed, so recording Command-W does not
    /// close the window. Escape cancels rather than being captured.
    private func arm() {
        isRecording = true
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
        isRecording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
