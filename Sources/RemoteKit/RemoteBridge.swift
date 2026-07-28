import Combine
import Defaults
import Foundation
import ServiceManagement

/// Ties the CEC link, the gesture rules and input synthesis together.
@MainActor
public final class RemoteBridge: ObservableObject {
    @Published public private(set) var status: BridgeStatus = .paused
    @Published public private(set) var displayName: String?
    @Published public private(set) var lastKey: RemoteKey?
    @Published public private(set) var isScrolling = false
    @Published public private(set) var log: [LogEntry] = []
    @Published public private(set) var hasAccessibility = InputSynthesizer.hasAccessibility

    @Published public var isEnabled: Bool {
        didSet {
            Defaults[.enabled] = isEnabled
            isEnabled ? link.start() : link.stop()
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

    // MARK: Bindings

    public func binding(for button: RemoteButton) -> ButtonBinding { bindings[button] }

    public func setBinding(_ binding: ButtonBinding, for button: RemoteButton) {
        bindings[button] = binding
        Defaults[.bindings] = bindings.customised
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

    // MARK: Login item

    public var launchesAtLogin: Bool { SMAppService.mainApp.status == .enabled }

    public func setLaunchesAtLogin(_ enabled: Bool) {
        do {
            try enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            append("Launch at login \(enabled ? "on" : "off")")
        } catch {
            append("Launch at login failed: \(error.localizedDescription)")
        }
        objectWillChange.send()
    }

    public func clearLog() { log.removeAll() }

    public func logText() -> String {
        log.map { "\($0.time)  \($0.message)" }.joined(separator: "\n")
    }
}

private extension RemoteBridge {
    var clock: TimeInterval { ProcessInfo.processInfo.systemUptime }

    /// Drives hold detection and the missed-release fallback.
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
        append("Link: \(state)")
        updateStatus()
    }

    func updateStatus() {
        status = BridgeStatus(link: linkState, hasAccessibility: hasAccessibility)
    }

    func handle(press key: RemoteKey) {
        lastKey = key
        if reader.heldKey != key { append("Press: \(key.title)") }
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

    func beginHold(_ button: RemoteButton) {
        guard permitted() else { return }
        let action = bindings[button].action
        input.hold(isScrolling ? action.scrolling : action, sensitivity: sensitivity)
    }

    func scheduleTrigger(_ button: RemoteButton, after delay: TimeInterval) {
        // Only worth waiting when the double-tap is actually bound.
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
    }

    /// Without Accessibility every posted event is dropped silently. Onboarding
    /// gates on it and the status reports it, so this only keeps the log honest.
    func permitted() -> Bool {
        guard hasAccessibility else {
            append("Ignored, no Accessibility permission")
            return false
        }
        return true
    }

    func append(_ message: String) {
        log.append(LogEntry(date: Date(), message: message))
        if log.count > 250 { log.removeFirst(log.count - 200) }
    }
}
