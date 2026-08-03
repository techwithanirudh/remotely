import AppKit
import Defaults
import Foundation
import RemotelyKit

@MainActor
final class RemoteClientLive {
    static let shared = RemoteClientLive()

    private let link = CECLink()
    private let input = InputSynthesizer()
    private var reader = GestureReader()
    private var linkState: CECLink.State = .stopped
    private var ticker: Timer?
    private var displayObserver: (any NSObjectProtocol)?
    private var deferred: DispatchWorkItem?
    private var continuation: AsyncStream<RemoteClient.Snapshot>.Continuation?

    private var status: RemoteStatus = .paused
    private var displayName: String?
    private var pressCount: UInt64 = 0
    private var isScrolling = false
    private var log: [RemoteClient.LogEntry] = []
    private var hasAccessibility = InputSynthesizer.hasAccessibility
    private var isEnabled = Defaults[.enabled]
    private var sensitivity = Defaults[.pointerSensitivity]
    private var bindings = Bindings.resolving(Defaults[.bindings])

    init() {
        link.onStateChange = { [weak self] state in self?.apply(state) }
        link.onPress = { [weak self] key in self?.handle(press: key) }
        link.onRelease = { [weak self] in self?.handleRelease() }
        link.onDisplayName = { [weak self] name in self?.displayName = name
            self?.emit()
        }
        link.onLog = { [weak self] message in self?.append(message) }
    }

    func events() -> AsyncStream<RemoteClient.Snapshot> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(snapshot())

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuation = nil
                }
            }
        }
    }

    func start() {
        watchDisplays()
        refreshPermission()
        if let display = AttachedDisplay.name {
            displayName = display
            append("Connected to \(display)")
        }
        if isEnabled { link.start() }
        startTicker()
        emit()
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        deferred?.cancel()
        deferred = nil
        link.stop()
        emit()
    }

    func reconnect() {
        append("Reconnecting")
        link.start()
    }

    func refreshPermission() {
        hasAccessibility = InputSynthesizer.hasAccessibility
        updateStatus()
        emit()
    }

    func requestPermission() {
        hasAccessibility = InputSynthesizer.requestAccessibility()
        updateStatus()
        emit()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        Defaults[.enabled] = enabled
        if enabled { link.start() } else { link.stop() }
        emit()
    }

    func setSensitivity(_ sensitivity: Double) {
        self.sensitivity = sensitivity
        Defaults[.pointerSensitivity] = sensitivity
        emit()
    }

    func setBinding(_ binding: ButtonBinding, for button: RemoteButton) {
        bindings[button] = binding
        Defaults[.bindings] = bindings.customized
        append("\(button.title) → \(binding.summary)")
    }

    func setAction(_ action: RemoteAction, for button: RemoteButton) {
        setBinding(ButtonBinding(action, combo: bindings[button].combo), for: button)
    }

    func setCombo(_ combo: KeyCombo, for button: RemoteButton) {
        setBinding(ButtonBinding(.keyboardShortcut, combo: combo), for: button)
    }

    func resetBinding(for button: RemoteButton) {
        setBinding(Bindings.standard[button], for: button)
    }

    func resetAllBindings() {
        bindings = .standard
        Defaults[.bindings] = Bindings()
        append("Bindings reset")
    }

    func resetPreferences() {
        Defaults.removeAll()
        sensitivity = Defaults[.pointerSensitivity]
        bindings = .resolving(Defaults[.bindings])
        pressCount = 0
        isScrolling = false
        log.removeAll()
        reader = GestureReader()
        deferred?.cancel()
        deferred = nil
        setEnabled(Defaults[.enabled])
        emit()
    }

    func clearLog() {
        log.removeAll()
        emit()
    }

    private var clock: TimeInterval { ProcessInfo.processInfo.systemUptime }

    private func watchDisplays() {
        guard displayObserver == nil else { return }
        displayObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateStatus()
                self?.emit()
            }
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.run(self.reader.elapse(to: self.clock))
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func apply(_ state: CECLink.State) {
        linkState = state
        append(state.description)
        updateStatus()
    }

    private func updateStatus() {
        status = RemoteStatus(
            link: linkState,
            hasAccessibility: hasAccessibility,
            hasDisplay: AttachedDisplay.isAttached
        )
    }

    private func handle(press key: RemoteKey) {
        pressCount &+= 1
        if reader.heldKey != key { append("Pressed \(key.title)") }
        run(reader.press(key, at: clock))
    }

    private func handleRelease() { run(reader.release(at: clock)) }

    private func run(_ events: [GestureReader.Event]) {
        for event in events {
            switch event {
            case .beginHold(let button): beginHold(button)
            case .endHold: input.release()
            case .trigger(let button): trigger(button)
            case .triggerDeferred(let button, let delay): scheduleTrigger(button, after: delay)
            case .cancelDeferred:
                deferred?.cancel()
                deferred = nil
            }
        }
        emit()
    }

    private func beginHold(_ button: RemoteButton) {
        let action = bindings[button].action
        guard action.isContinuous else {
            trigger(button)
            return
        }
        guard permitted() else { return }
        input.hold(isScrolling ? action.scrolling : action, sensitivity: sensitivity)
    }

    private func scheduleTrigger(_ button: RemoteButton, after delay: TimeInterval) {
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

    private func trigger(_ button: RemoteButton) {
        guard permitted() else { return }
        let binding = bindings[button]

        if binding.action == .toggleScrolling {
            isScrolling.toggle()
            append(isScrolling ? "Scrolling on" : "Scrolling off")
            return
        }
        input.perform(binding)
        if !input.lastNavigation.isEmpty { append(input.lastNavigation) }
    }

    private func permitted() -> Bool {
        guard hasAccessibility else {
            append("Ignored, no Accessibility permission yet")
            return false
        }
        return true
    }

    private func append(_ message: String) {
        log.append(RemoteClient.LogEntry(date: Date(), message: message))
        if log.count > 250 { log.removeFirst(log.count - 200) }
        emit()
    }

    private func emit() { continuation?.yield(snapshot()) }

    private func snapshot() -> RemoteClient.Snapshot {
        RemoteClient.Snapshot(
            status: status,
            displayName: displayName,
            pressCount: pressCount,
            isScrolling: isScrolling,
            log: log,
            hasAccessibility: hasAccessibility,
            isEnabled: isEnabled,
            sensitivity: sensitivity,
            bindings: bindings
        )
    }
}
