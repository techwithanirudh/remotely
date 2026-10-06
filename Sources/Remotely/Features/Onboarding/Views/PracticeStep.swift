import AppKit
import RemotelyKit
import SwiftUI

struct PracticeStep: View {
    let exercise: PracticeExercise
    var isScrolling = false

    @State private var outcome: PracticeOutcome = .waiting
    @State private var monitor: Any?

    init(_ exercise: PracticeExercise, isScrolling: Bool = false) {
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
                    ForEach(1 ... 18, id: \.self) { row in
                        Text("Scrollable line \(row)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Theme.Card.inset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 92)
            .card()
            .background(TargetProbe())

            verdict
        } else {
            PracticeMarker(
                outcome: outcome,
                idleSymbol: exercise.idleSymbol,
                prompt: exercise.prompt
            )
            .background(TargetProbe())
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
            let inside = MainActor
                .assumeIsolated { TargetProbe.contains(NSEvent.mouseLocation) }

            if let result = exercise.judge(event, fromRemote: fromRemote, insideTarget: inside) {
                MainActor.assumeIsolated {
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
