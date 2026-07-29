import AppKit
import RemoteKit
import SwiftUI

/// One gesture per screen, each against a real control.
///
/// Because these are real events, a trackpad would satisfy every one of them,
/// which would teach nothing. Each target checks the signature the app stamps
/// onto the events it posts, and says which gesture actually arrived when it is
/// the wrong one.
struct PracticeStep: View {
    enum Exercise {
        case move, click, doubleClick, rightClick, scroll

        var title: String {
            switch self {
            case .move: "Hold an arrow to move the pointer"
            case .click: "Press Center to click"
            case .doubleClick: "Press Center twice to double-click"
            case .rightClick: "Hold Center for a right click"
            case .scroll: "Press Back twice to scroll"
            }
        }

        var hint: String {
            switch self {
            case .move: "Holding speeds up the longer you hold. A quick tap nudges a few pixels."
            case .click: "Move onto something first, then press Center once."
            case .doubleClick: "Two quick presses, the gesture that opens files and folders."
            case .rightClick: "Keep Center held for about half a second."
            case .scroll: "That switches the arrows between moving the pointer and scrolling."
            }
        }

        var symbol: String {
            switch self {
            case .move: "arrow.up.and.down.and.arrow.left.and.right"
            case .click: "cursorarrow.click"
            case .doubleClick: "cursorarrow.rays"
            case .rightClick: "contextualmenu.and.cursorarrow"
            case .scroll: "arrow.up.and.down.text.horizontal"
            }
        }

        var tint: Color {
            switch self {
            case .move: .blue
            case .click: .purple
            case .doubleClick: .pink
            case .rightClick: .indigo
            case .scroll: .teal
            }
        }

        var idleSymbol: String {
            switch self {
            case .move: "scope"
            case .click: "cursorarrow"
            case .doubleClick: "2.circle"
            case .rightClick: "hand.point.up.left"
            case .scroll: "arrow.up.arrow.down"
            }
        }

        var prompt: String {
            switch self {
            case .move: "Move the pointer with an arrow"
            case .click: "Press Center once"
            case .doubleClick: "Press Center twice, quickly"
            case .rightClick: "Hold Center to open a menu here"
            case .scroll: "Scroll this list"
            }
        }

        var mask: NSEvent.EventTypeMask {
            switch self {
            case .move: .mouseMoved
            case .click, .doubleClick: .leftMouseDown
            case .rightClick: [.rightMouseDown, .leftMouseDown]
            case .scroll: [.scrollWheel, .mouseMoved]
            }
        }

        /// nil ignores the event entirely.
        ///
        /// - Parameter insideTarget: whether the pointer is over the exercise's
        ///   own control. Movement elsewhere is just travelling towards it.
        func judge(_ event: NSEvent, fromRemote: Bool, insideTarget: Bool) -> Outcome? {
            guard fromRemote else {
                return self == .move ? nil : .wrong("That was your mouse, not the remote.")
            }

            switch self {
            case .move:
                return .passed

            case .scroll:
                if event.type == .scrollWheel { return .passed }
                // Moving over the list means the arrows are still in pointer
                // mode. Moving anywhere else is just travelling here.
                return insideTarget
                    ? .wrong("Still moving the pointer. Press Back twice first.")
                    : nil

            // A press away from the target is aimed at something else, so it is
            // neither a pass nor a mistake.
            case .click:
                guard insideTarget else { return nil }
                return event.clickCount >= 2
                    ? .wrong("That was a double press. Try one on its own.")
                    : .passed

            case .doubleClick:
                guard insideTarget else { return nil }
                return event.clickCount >= 2
                    ? .passed
                    : .wrong("Only one press registered. Press again faster.")

            case .rightClick:
                guard insideTarget else { return nil }
                return event.type == .rightMouseDown
                    ? .passed
                    : .wrong("That was a normal click. Hold Center longer.")
            }
        }
    }

    enum Outcome: Equatable {
        case waiting
        case wrong(String)
        case passed
    }

    let exercise: Exercise
    var isScrolling = false

    @State private var outcome: Outcome = .waiting
    @State private var monitor: Any?

    init(_ exercise: Exercise, isScrolling: Bool = false) {
        self.exercise = exercise
        self.isScrolling = isScrolling
    }

    var body: some View {
        StepLayout(title: exercise.title, hint: hint) {
            GestureHero(symbol: exercise.symbol, tint: exercise.tint)
        } content: {
            VStack(spacing: 9) {
                if exercise == .scroll {
                    ModeBadge(isScrolling: isScrolling)
                }
                target
            }
        }
        .onAppear(perform: watch)
        .onDisappear(perform: unwatch)
    }

    private var hint: String {
        guard exercise == .scroll, isScrolling else { return exercise.hint }
        return "Scrolling is on. Press Back twice again to go back to moving."
    }

    @ViewBuilder
    private var target: some View {
        if exercise == .scroll {
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
            .card()
            .background(ScrollAreaProbe())

            verdict
        } else {
            Marker(outcome: outcome, idleSymbol: exercise.idleSymbol, prompt: exercise.prompt)
                .background(ScrollAreaProbe())
                // A real menu, so the gesture is proven end to end rather than
                // just registering that a right click happened.
                .contextMenu {
                    if exercise == .rightClick {
                        Text("Your remote opened this")
                        Divider()
                        Button("Nice") {}
                    }
                }
        }
    }

    @ViewBuilder
    private var verdict: some View {
        switch outcome {
        case .passed:
            Label("Scrolled", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.green)
        case .wrong(let reason):
            Text(reason)
                .font(.system(size: 11))
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        case .waiting:
            Text("Press Back twice, then hold an arrow")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func watch() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: exercise.mask) { event in
            let fromRemote = EventSignature.marks(event)
            let inside = MainActor.assumeIsolated { ScrollAreaProbe.contains(NSEvent.mouseLocation) }

            if let result = exercise.judge(event, fromRemote: fromRemote, insideTarget: inside) {
                MainActor.assumeIsolated {
                    // Passing is final: a stray event afterwards should not
                    // report a failure the user has already got past.
                    if outcome != .passed { outcome = result }
                }
            }
            return event
        }
    }

    private func unwatch() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

private struct Marker: View {
    let outcome: PracticeStep.Outcome
    let idleSymbol: String
    let prompt: String

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
        .card()
    }

    private var fill: Color {
        switch outcome {
        case .waiting: .primary.opacity(0.12)
        case .wrong: .orange
        case .passed: .green
        }
    }

    private var symbol: String {
        switch outcome {
        case .waiting: idleSymbol
        case .wrong: "exclamationmark"
        case .passed: "checkmark"
        }
    }

    private var tint: Color {
        switch outcome {
        case .wrong: .orange
        case .passed: .green
        case .waiting: .secondary
        }
    }

    private var caption: String {
        switch outcome {
        case .waiting: prompt
        case .wrong(let reason): reason
        case .passed: "That came from the remote"
        }
    }
}

/// Says which mode the D-pad is in right now.
struct ModeBadge: View {
    let isScrolling: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isScrolling
                  ? "arrow.up.and.down.text.horizontal"
                  : "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 10, weight: .semibold))

            Text(isScrolling ? "Scrolling" : "Moving the pointer")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(isScrolling ? Color.accentColor : .secondary)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            (isScrolling ? Color.accentColor : .primary).opacity(isScrolling ? 0.15 : 0.07),
            in: Capsule()
        )
        .animation(.easeOut(duration: 0.18), value: isScrolling)
    }
}


/// Reports where the step's target sits on screen, so input can be judged
/// against it rather than against the whole panel.
///
/// Measured when asked rather than cached. The panel lays out at the origin and
/// is centered afterwards, so a frame recorded during layout described a patch of
/// screen the card had since left, and presses well outside the card counted.
struct ScrollAreaProbe: NSViewRepresentable {
    @MainActor private static weak var current: Probe?

    @MainActor
    static func contains(_ point: NSPoint) -> Bool {
        current?.screenFrame.contains(point) ?? false
    }

    func makeNSView(context: Context) -> NSView { Probe() }
    func updateNSView(_ view: NSView, context: Context) {}

    private final class Probe: NSView {
        var screenFrame: NSRect {
            guard let window else { return .zero }
            return window.convertToScreen(convert(bounds, to: nil))
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            MainActor.assumeIsolated { ScrollAreaProbe.current = self }
        }
    }
}
