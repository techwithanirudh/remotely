import SwiftUI
import AppKit

/// The practice steps.
///
/// One action per screen, each with a single target. These are real events, so
/// the trackpad would satisfy every one of them — which would teach the user
/// nothing. Each target checks the signature Remote Bridge stamps onto the
/// events it injects and rejects anything that came from the actual mouse.

/// Watches mouse events and reports whether they came from the remote.
@MainActor
private final class PracticeMonitor: ObservableObject {
    enum Outcome: Equatable {
        case waiting
        case wrongSource
        case satisfied
    }

    @Published private(set) var outcome: Outcome = .waiting

    private var monitor: Any?

    /// - Parameter accepts: which events count as completing the exercise.
    func start(matching mask: NSEvent.EventTypeMask, accepts: @escaping (NSEvent) -> Bool) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            // The monitor already runs on the main thread; NSEvent is not
            // Sendable, so decide here and hand the result across.
            if accepts(event) {
                let fromRemote = RemoteEventSignature.marks(event)
                MainActor.assumeIsolated {
                    self.outcome = fromRemote ? .satisfied : .wrongSource
                }
            }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

/// Shared target: a dot that only lights up for remote-driven input.
private struct PracticeTarget: View {
    let outcome: PracticeMonitor.Outcome
    let idleSymbol: String

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(fill)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(outcome == .waiting ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.white))
                }

            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(outcome == .wrongSource ? .orange : .secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardSurface(cornerRadius: Theme.cardCornerRadius)
    }

    private var fill: Color {
        switch outcome {
        case .waiting: Color.primary.opacity(0.12)
        case .wrongSource: .orange
        case .satisfied: .green
        }
    }

    private var symbol: String {
        switch outcome {
        case .waiting: idleSymbol
        case .wrongSource: "exclamationmark"
        case .satisfied: "checkmark"
        }
    }

    private var caption: String {
        switch outcome {
        case .waiting: "Waiting for the remote"
        case .wrongSource: "That was your mouse. Try the remote."
        case .satisfied: "That came from the remote"
        }
    }
}

struct MoveStep: View {
    @StateObject private var monitor = PracticeMonitor()

    var body: some View {
        OnboardingStep(
            title: "Hold an arrow to move the pointer",
            hint: "Holding speeds up the longer you hold. A quick tap nudges a few pixels."
        ) {
            PermissionDialogMock(symbol: "arrow.up.and.down.and.arrow.left.and.right",
                                 tint: .blue)
        } accessory: {
            PracticeTarget(outcome: monitor.outcome, idleSymbol: "scope")
                .onAppear {
                    monitor.start(matching: .mouseMoved) { _ in true }
                }
                .onDisappear { monitor.stop() }
        }
    }
}

struct ClickStep: View {
    @StateObject private var monitor = PracticeMonitor()

    var body: some View {
        OnboardingStep(
            title: "Press Center to click",
            hint: "Move onto something, then press Center once."
        ) {
            PermissionDialogMock(symbol: "cursorarrow.click", tint: .purple)
        } accessory: {
            PracticeTarget(outcome: monitor.outcome, idleSymbol: "cursorarrow")
                .onAppear {
                    monitor.start(matching: .leftMouseDown) { $0.clickCount == 1 }
                }
                .onDisappear { monitor.stop() }
        }
    }
}

struct DoubleClickStep: View {
    @StateObject private var monitor = PracticeMonitor()

    var body: some View {
        OnboardingStep(
            title: "Press Center twice to double-click",
            hint: "Two quick presses. This is what opens files and folders."
        ) {
            PermissionDialogMock(symbol: "cursorarrow.rays", tint: .pink)
        } accessory: {
            PracticeTarget(outcome: monitor.outcome, idleSymbol: "2.circle")
                .onAppear {
                    monitor.start(matching: .leftMouseDown) { $0.clickCount >= 2 }
                }
                .onDisappear { monitor.stop() }
        }
    }
}

struct RightClickStep: View {
    @StateObject private var monitor = PracticeMonitor()

    var body: some View {
        OnboardingStep(
            title: "Hold Center for a right click",
            hint: "Keep Center held for half a second to open a context menu."
        ) {
            PermissionDialogMock(symbol: "contextualmenu.and.cursorarrow", tint: .indigo)
        } accessory: {
            // A real context menu, so the gesture is proven end to end rather
            // than just registering that a right click happened.
            PracticeTarget(outcome: monitor.outcome, idleSymbol: "hand.point.up.left")
                .contextMenu {
                    Text("This is a context menu")
                    Divider()
                    Button("Your remote opened it") {}
                }
                .onAppear {
                    monitor.start(matching: .rightMouseDown) { _ in true }
                }
                .onDisappear { monitor.stop() }
        }
    }
}

struct ScrollStep: View {
    @ObservedObject var model: BridgeModel
    @StateObject private var monitor = PracticeMonitor()

    var body: some View {
        OnboardingStep(
            title: "Press Back twice to scroll",
            hint: model.scrollMode
                ? "Scrolling is on. Press Back twice again to go back to moving."
                : "That switches the arrows between moving the pointer and scrolling."
        ) {
            PermissionDialogMock(symbol: "arrow.up.and.down.text.horizontal", tint: .teal)
        } accessory: {
            PracticeTarget(outcome: monitor.outcome, idleSymbol: "arrow.up.arrow.down")
                .onAppear {
                    monitor.start(matching: .scrollWheel) { _ in true }
                }
                .onDisappear { monitor.stop() }
        }
    }
}
