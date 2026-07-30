import Combine
import Defaults
import Foundation

@MainActor
public final class RemoteBridge: ObservableObject {
    @Published public private(set) var status: BridgeStatus = .paused
    @Published public private(set) var displayName: String?
    @Published public private(set) var pressCount: UInt64 = 0
    @Published public private(set) var isScrolling = false
    @Published public private(set) var log: [LogEntry] = []
    @Published public private(set) var hasAccessibility = InputSynthesizer.hasAccessibility

    @Published public var isEnabled: Bool {
        didSet {
            Defaults[.enabled] = isEnabled
            if isEnabled {
                link.start()
            } else {
                link.stop()
            }
        }
    }

    @Published public var sensitivity: Double {
        didSet { Defaults[.pointerSensitivity] = sensitivity }
    }

    @Published public private(set) var bindings: Bindings

    public struct LogEntry: Identifiable, Hashable, Sendable {
        public let id = UUID()
        public let date: Date
        public let message: String

        public var time: String { date.formatted(date: .omitted, time: .standard) }
    }

    private let link = CECLink()
    private let input = InputSynthesizer()
    private var reader = GestureReader()
    private var linkState: CECLink.State = .stopped

    private var ticker: Timer?
    private var deferred: DispatchWorkItem?

    public var onScrollingChange: ((Bool) -> Void)?

    public init() {
        isEnabled = Defaults[.enabled]
        sensitivity = Defaults[.pointerSensitivity]
        bindings = .resolving(Defaults[.bindings])

        link.onStateChange = { [weak self] state in self?.apply(state) }
        link.onPress = { [weak self] key in self?.handle(press: key) }
        link.onRelease = { [weak self] in self?.handleRelease() }
        link.onDisplayName = { [weak self] name in self?.displayName = name }
        link.onLog = { [weak self] message in self?.append(message) }
    }

    public func start() {
        refreshPermission()
        if isEnabled { link.start() }
        startTicker()
    }

    public func stop() {
        ticker?.invalidate()
        ticker = nil
        deferred?.cancel()
        link.stop()
    }

    public func reconnect() {
        append("Reconnecting")
        link.start()
    }

    public func refreshPermission() {
        hasAccessibility = InputSynthesizer.hasAccessibility
        updateStatus()
    }

    public func requestPermission() {
        hasAccessibility = InputSynthesizer.requestAccessibility()
        updateStatus()
    }

    public func binding(for button: RemoteButton) -> ButtonBinding { bindings[button] }

    public func setBinding(_ binding: ButtonBinding, for button: RemoteButton) {
        bindings[button] = binding
        Defaults[.bindings] = bindings.customized
        append("\(button.title) → \(binding.summary)")
    }

    /// Keeps any recorded combination, so switching away and back does not
    /// silently discard it.
    public func setAction(_ action: RemoteAction, for button: RemoteButton) {
        setBinding(ButtonBinding(action, combo: bindings[button].combo), for: button)
    }

    public func setCombo(_ combo: KeyCombo, for button: RemoteButton) {
        setBinding(ButtonBinding(.keyboardShortcut, combo: combo), for: button)
    }

    public func isStandard(_ button: RemoteButton) -> Bool { bindings.isStandard(button) }

    public func resetBinding(for button: RemoteButton) {
        setBinding(Bindings.standard[button], for: button)
    }

    public func resetAllBindings() {
        bindings = .standard
        Defaults[.bindings] = Bindings()
        append("Bindings reset")
    }

    public func resetPreferences() {
        Defaults.removeAll()
        sensitivity = Defaults[.pointerSensitivity]
        bindings = .resolving(Defaults[.bindings])
        pressCount = 0
        isScrolling = false
        log.removeAll()
        reader = GestureReader()
        deferred?.cancel()
        deferred = nil
        isEnabled = Defaults[.enabled]
    }

    public func clearLog() { log.removeAll() }

    public func logText() -> String {
        log.map { "\($0.time)  \($0.message)" }.joined(separator: "\n")
    }
}

private extension RemoteBridge {
    var clock: TimeInterval { ProcessInfo.processInfo.systemUptime }

    func startTicker() {
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.run(self.reader.elapse(to: self.clock))
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func apply(_ state: CECLink.State) {
        linkState = state
        append(state.description)
        updateStatus()
    }

    func updateStatus() {
        status = BridgeStatus(link: linkState, hasAccessibility: hasAccessibility)
    }

    func handle(press key: RemoteKey) {
        pressCount &+= 1
        if reader.heldKey != key { append("Pressed \(key.title)") }
        run(reader.press(key, at: clock))
    }

    func handleRelease() {
        run(reader.release(at: clock))
    }

    func run(_ events: [GestureReader.Event]) {
        for event in events {
            switch event {
            case .beginHold(let button):
                beginHold(button)
            case .endHold:
                input.release()
            case .trigger(let button):
                trigger(button)
            case .triggerDeferred(let button, let delay):
                scheduleTrigger(button, after: delay)
            case .cancelDeferred:
                deferred?.cancel()
                deferred = nil
            }
        }
    }

    /// An arrow key is held rather than tapped, but any action can be bound to
    /// one. Only the actions that move something can be glided; the rest fire
    /// once, as the key goes down, or pressing an arrow bound to Show Desktop
    /// would do nothing at all.
    func beginHold(_ button: RemoteButton) {
        let action = bindings[button].action
        guard action.isContinuous else {
            trigger(button)
            return
        }
        guard permitted() else { return }
        input.hold(isScrolling ? action.scrolling : action, sensitivity: sensitivity)
    }

    func scheduleTrigger(_ button: RemoteButton, after delay: TimeInterval) {
        guard bindings[.backDouble].action != .none else {
            trigger(button)
            return
        }
        let work = DispatchWorkItem { [weak self] in
            self?.trigger(button)
            self?.deferred = nil
        }
        deferred = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func trigger(_ button: RemoteButton) {
        guard permitted() else { return }
        let binding = bindings[button]

        if binding.action == .toggleScrolling {
            isScrolling.toggle()
            onScrollingChange?(isScrolling)
            append(isScrolling ? "Scrolling on" : "Scrolling off")
            return
        }
        input.perform(binding)
        if !input.lastNavigation.isEmpty { append(input.lastNavigation) }
    }

    /// Without Accessibility every posted event is dropped silently. Onboarding
    /// gates on it and the status reports it, so this only keeps the log honest.
    func permitted() -> Bool {
        guard hasAccessibility else {
            append("Ignored, no Accessibility permission yet")
            return false
        }
        return true
    }

    func append(_ message: String) {
        log.append(LogEntry(date: Date(), message: message))
        if log.count > 250 { log.removeFirst(log.count - 200) }
    }
}
