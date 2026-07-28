import SwiftUI
import AppKit

/// The practice steps.
///
/// One gesture per screen, each against a real control. Because these are real
/// events, a trackpad satisfies every one of them, which would teach nothing —
/// so each target checks the signature Remote Bridge stamps onto the events it
/// injects, and says which gesture actually arrived when it is the wrong one.

/// Watches input and reports whether the right gesture arrived from the remote.
@MainActor
final class PracticeMonitor: ObservableObject {
    enum Outcome: Equatable {
        case waiting
        /// Something arrived, but not what the step asked for.
        case wrong(String)
        case satisfied

        var isSatisfied: Bool { self == .satisfied }
    }

    @Published private(set) var outcome: Outcome = .waiting

    private var monitor: Any?

    /// - Parameter classify: given the event and whether it came from the
    ///   remote, return the outcome, or nil to ignore the event entirely.
    func start(
        matching mask: NSEvent.EventTypeMask,
        classify: @escaping (NSEvent, Bool) -> Outcome?
    ) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            // Runs on the main thread already; NSEvent is not Sendable, so the
            // decision is made here and only the result crosses over.
            let fromRemote = RemoteEventSignature.marks(event)
            if let result = classify(event, fromRemote) {
                MainActor.assumeIsolated {
                    // Passing is final. Otherwise the next stray event after a
                    // success — a pointer move once scrolling worked, say —
                    // reported a failure the user had already got past.
                    guard self.outcome != .satisfied else { return }
                    self.outcome = result
                }
            }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    /// Standard rejection for input that came from the physical mouse.
    static let notRemote = Outcome.wrong("That was your mouse, not the remote.")
}

/// Shared target: only lights up for the right gesture from the remote.
struct PracticeTarget: View {
    let outcome: PracticeMonitor.Outcome
    let idleSymbol: String
    let idleCaption: String
    var doneCaption = "That came from the remote"

    var body: some View {
        VStack(spacing: 9) {
            Circle()
                .fill(fill)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(outcome == .waiting
                                         ? AnyShapeStyle(.secondary)
                                         : AnyShapeStyle(Color.white))
                }
                .animation(.easeOut(duration: 0.15), value: outcome)

            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .cardSurface(cornerRadius: Theme.cardCornerRadius)
    }

    private var fill: Color {
        switch outcome {
        case .waiting: Color.primary.opacity(0.12)
        case .wrong: .orange
        case .satisfied: .green
        }
    }

    private var symbol: String {
        switch outcome {
        case .waiting: idleSymbol
        case .wrong: "exclamationmark"
        case .satisfied: "checkmark"
        }
    }

    private var tint: Color {
        switch outcome {
        case .wrong: .orange
        case .satisfied: .green
        default: .secondary
        }
    }

    private var caption: String {
        switch outcome {
        case .waiting: idleCaption
        case .wrong(let reason): reason
        case .satisfied: doneCaption
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
            PracticeTarget(
                outcome: monitor.outcome,
                idleSymbol: "scope",
                idleCaption: "Move the pointer with an arrow",
                doneCaption: "The remote is moving the pointer"
            )
            .onAppear {
                monitor.start(matching: .mouseMoved) { _, fromRemote in
                    // A real mouse constantly emits moves; only report the
                    // mismatch once the exercise has not been satisfied yet.
                    fromRemote ? .satisfied : nil
                }
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
            hint: "Move onto something first, then press Center once."
        ) {
            PermissionDialogMock(symbol: "cursorarrow.click", tint: .purple)
        } accessory: {
            PracticeTarget(
                outcome: monitor.outcome,
                idleSymbol: "cursorarrow",
                idleCaption: "Press Center once"
            )
            .onAppear {
                monitor.start(matching: .leftMouseDown) { event, fromRemote in
                    guard fromRemote else { return PracticeMonitor.notRemote }
                    return event.clickCount >= 2
                        ? .wrong("That was a double press. Try one on its own.")
                        : .satisfied
                }
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
            hint: "Two quick presses, the gesture that opens files and folders."
        ) {
            PermissionDialogMock(symbol: "cursorarrow.rays", tint: .pink)
        } accessory: {
            PracticeTarget(
                outcome: monitor.outcome,
                idleSymbol: "2.circle",
                idleCaption: "Press Center twice, quickly"
            )
            .onAppear {
                monitor.start(matching: .leftMouseDown) { event, fromRemote in
                    guard fromRemote else { return PracticeMonitor.notRemote }
                    return event.clickCount >= 2
                        ? .satisfied
                        : .wrong("Only one press registered. Press again faster.")
                }
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
            hint: "Keep Center held for about half a second."
        ) {
            PermissionDialogMock(symbol: "contextualmenu.and.cursorarrow", tint: .indigo)
        } accessory: {
            // A real context menu, so the gesture is proven end to end rather
            // than just registering that a right click happened.
            PracticeTarget(
                outcome: monitor.outcome,
                idleSymbol: "hand.point.up.left",
                idleCaption: "Hold Center to open a menu here",
                doneCaption: "That opened a context menu"
            )
            .contextMenu {
                Text("Your remote opened this")
                Divider()
                Button("Nice") {}
            }
            .onAppear {
                monitor.start(matching: [.rightMouseDown, .leftMouseDown]) { event, fromRemote in
                    guard fromRemote else { return PracticeMonitor.notRemote }
                    return event.type == .rightMouseDown
                        ? .satisfied
                        : .wrong("That was a normal click. Hold Center longer.")
                }
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
            hint: "That switches the arrows between moving the pointer and scrolling."
        ) {
            PermissionDialogMock(symbol: "arrow.up.and.down.text.horizontal", tint: .teal)
        } accessory: {
            VStack(spacing: 9) {
                // Without this there is no way to tell which mode you are in.
                ScrollModeBadge(active: model.scrollMode)

                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(1...18, id: \.self) { row in
                            Text("Scrollable line \(row)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 92)
                .cardSurface(cornerRadius: Theme.cardCornerRadius)
                .overlay(alignment: .bottomTrailing) {
                    if monitor.outcome.isSatisfied {
                        Label("Scrolled", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.green)
                            .padding(7)
                    }
                }

                if case .wrong(let reason) = monitor.outcome {
                    Text(reason)
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onAppear {
                monitor.start(matching: [.scrollWheel, .mouseMoved]) { event, fromRemote in
                    guard fromRemote else { return nil }
                    if event.type == .scrollWheel { return .satisfied }
                    return model.scrollMode
                        ? nil
                        : .wrong("Still moving the pointer. Press Back twice first.")
                }
            }
            .onDisappear { monitor.stop() }
        }
    }
}

/// Says which mode the D-pad is in right now.
struct ScrollModeBadge: View {
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: active
                  ? "arrow.up.and.down.text.horizontal"
                  : "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 10, weight: .semibold))

            Text(active ? "Scrolling" : "Moving the pointer")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(active ? Color.accentColor : Color.secondary)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            (active ? Color.accentColor : Color.primary).opacity(active ? 0.15 : 0.07),
            in: Capsule()
        )
        .animation(.easeOut(duration: 0.18), value: active)
    }
}
