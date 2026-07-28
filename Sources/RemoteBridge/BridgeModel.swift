import AppKit
import ApplicationServices
import Combine
import ServiceManagement
import RemoteCore

struct BridgeLogEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let message: String

    var timestamp: String {
        date.formatted(date: .omitted, time: .standard)
    }
}

@MainActor
final class BridgeModel: ObservableObject {
    @Published private(set) var connectionState: CECClient.State = .stopped
    @Published private(set) var lastCommand: RemoteCommand?
    @Published private(set) var lastButton: RemoteButton?
    @Published private(set) var highlightedButton: RemoteButton?
    @Published private(set) var lastMappedAction: MacAction?
    @Published private(set) var buttonEventCount = 0
    @Published private(set) var logs: [BridgeLogEntry] = []
    @Published private(set) var accessibilityGranted = AXIsProcessTrusted()
    @Published private(set) var launchAtLoginEnabled =
        SMAppService.mainApp.status == .enabled
    @Published var lastError: String?

    @Published var bridgeEnabled: Bool {
        didSet {
            defaults.set(bridgeEnabled, forKey: Keys.bridgeEnabled)
            bridgeEnabled ? client.start() : client.stop()
        }
    }

    @Published private(set) var bindings: RemoteBindings

    /// Name reported by the attached display's EDID, once CEC traffic is seen.
    @Published private(set) var displayName: String?

    /// Multiplier on the pointer's start speed and acceleration.
    @Published var pointerSensitivity: Double {
        didSet { defaults.set(pointerSensitivity, forKey: Keys.pointerSensitivity) }
    }

    /// While on, the D-pad scrolls instead of moving the pointer.
    @Published private(set) var scrollMode = false {
        didSet { scrollIndicator.setVisible(scrollMode) }
    }

    let client = CECClient()
    private let controller = MacController()
    private let scrollIndicator = ScrollModeIndicator()
    private let defaults = UserDefaults.standard
    private var pendingBack: DispatchWorkItem?
    private var clearHighlightWork: DispatchWorkItem?
    private var heldCommand: RemoteCommand?
    private var heldSince = Date.distantPast
    private var lastRepeatAt = Date.distantPast
    private var lastTapAt = Date.distantPast
    private var holdWatchdog: Timer?
    private var holdGesture: DispatchWorkItem?
    private var heldFired = false
    private var lastPermissionNotice = Date.distantPast

    private static let holdThreshold: TimeInterval = 0.5
    private static let doubleTapWindow: TimeInterval = 0.38

    private enum Keys {
        static let bridgeEnabled = "bridgeEnabled"
        static let pointerSensitivity = "pointerSensitivity"
        static let bindings = "buttonBindings.v3"
    }

    init() {
        defaults.register(defaults: [
            Keys.bridgeEnabled: true,
            Keys.pointerSensitivity: 1.0,
        ])
        bridgeEnabled = defaults.bool(forKey: Keys.bridgeEnabled)
        pointerSensitivity = defaults.double(forKey: Keys.pointerSensitivity)
        bindings = Self.loadBindings(from: defaults)

        client.onStateChange = { [weak self] state in
            self?.connectionState = state
            self?.appendLog("Connection: \(state)")
        }
        client.onCommand = { [weak self] command in
            self?.receive(command)
        }
        client.onRelease = { [weak self] in
            self?.receiveRelease()
        }
        client.onLog = { [weak self] message in
            self?.appendLog(message)
        }
        client.onDisplayChange = { [weak self] name in
            self?.displayName = name
        }
    }

    func start() {
        refreshPermissions()
        if bridgeEnabled { client.start() }
    }

    func stop() {
        pendingBack?.cancel()
        clearHighlightWork?.cancel()
        client.stop()
    }

    func reconnect() {
        appendLog("Manual reconnect requested")
        client.start()
    }

    func requestAccessibility() {
        accessibilityGranted = controller.requestAccessibilityPermission()
        appendLog(accessibilityGranted
            ? "Accessibility permission is active"
            : "Accessibility permission requested")
    }

    func refreshPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            appendLog("Launch at login \(launchAtLoginEnabled ? "enabled" : "disabled")")
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            lastError = error.localizedDescription
            appendLog("Launch at login error: \(error.localizedDescription)")
        }
    }

    func binding(for button: RemoteButton) -> RemoteBinding {
        bindings[button]
    }

    func action(for button: RemoteButton) -> MacAction {
        bindings[button].action
    }

    func setBinding(_ binding: RemoteBinding, for button: RemoteButton) {
        bindings[button] = binding
        saveBindings()
        appendLog("\(button.title) mapped to \(binding.summary)")
    }

    func setAction(_ action: MacAction, for button: RemoteButton) {
        // Keep any recorded combination, so flipping away and back does not
        // silently discard it.
        setBinding(RemoteBinding(action, shortcut: bindings[button].shortcut), for: button)
    }

    func setShortcut(_ shortcut: KeyboardShortcut, for button: RemoteButton) {
        setBinding(RemoteBinding(.keyboardShortcut, shortcut: shortcut), for: button)
    }

    func isDefaultAction(for button: RemoteButton) -> Bool {
        bindings.isDefault(button)
    }

    func resetAction(for button: RemoteButton) {
        setBinding(RemoteBindings.defaults[button], for: button)
    }

    func resetMappings() {
        bindings = .defaults
        saveBindings()
        appendLog("Button mappings reset to defaults")
    }

    func previewButton(_ button: RemoteButton) {
        flash(button)
        appendLog("Preview: \(button.title) → \(action(for: button).title)")
    }

    func copyLogs() {
        let value = logs.map { "\($0.timestamp)  \($0.message)" }
            .joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    func clearLogs() {
        logs.removeAll()
    }

    /// A CEC press repeats while the key is held and ends with a single release
    /// that carries no key code, so hold and double-tap are derived from timing.
    private func receive(_ command: RemoteCommand) {
        lastCommand = command

        // Repeats only keep the hold alive; the timer already drives movement.
        guard command != heldCommand else {
            lastRepeatAt = Date()
            return
        }

        finishHeldCommand(released: false)
        heldCommand = command
        heldSince = Date()
        lastRepeatAt = Date()
        appendLog("Button: \(command.displayName)")

        if command.isDirectional {
            beginDirectional(command)
        } else {
            armHoldGesture(for: command)
        }
    }

    private func receiveRelease() {
        finishHeldCommand(released: true)
    }

    /// Fires a hold as soon as it qualifies, rather than waiting for release.
    /// A right click that only appears once you let go feels broken: every
    /// other press-and-hold on the system acts while your finger is still down.
    private func armHoldGesture(for command: RemoteCommand) {
        holdGesture?.cancel()
        guard command == .select, action(for: .centerHold) != .none else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self, self.heldCommand == .select else { return }
            self.heldFired = true
            self.trigger(.centerHold)
        }
        holdGesture = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.holdThreshold, execute: work)
    }

    private func beginDirectional(_ command: RemoteCommand) {
        guard let button = RemoteButton(command: command) else { return }
        flash(button)
        guard permitToAct() else { return }
        let action = action(for: button)
        controller.beginHold(scrollMode ? action.scrollEquivalent : action,
                             sensitivity: pointerSensitivity)
        startHoldWatchdog()
    }

    /// A dropped release would otherwise leave the pointer gliding forever, so
    /// stop once the key's repeats go quiet.
    private func startHoldWatchdog() {
        holdWatchdog?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard Date().timeIntervalSince(self.lastRepeatAt) > 0.6 else { return }
                self.finishHeldCommand(released: false)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        holdWatchdog = timer
    }

    private func finishHeldCommand(released: Bool) {
        guard let command = heldCommand else { return }
        heldCommand = nil

        holdGesture?.cancel()
        holdGesture = nil

        if command.isDirectional {
            holdWatchdog?.invalidate()
            holdWatchdog = nil
            controller.endHold()
            return
        }

        // The hold already fired while the key was down; releasing must not
        // also register a tap.
        if heldFired {
            heldFired = false
            return
        }
        guard released else { return }

        switch command {
        case .select:
            trigger(isDoubleTap() ? .centerDouble : .center)
        case .back:
            if isDoubleTap() {
                pendingBack?.cancel()
                pendingBack = nil
                trigger(.doubleBack)
            } else {
                scheduleSingleBack()
            }
        default:
            break
        }
    }

    /// Discrete actions wait out the double-tap window; clicks do not, because
    /// a second click simply escalates the first into a real double-click.
    private func scheduleSingleBack() {
        guard action(for: .doubleBack) != .none else {
            trigger(.back)
            return
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.trigger(.back)
            self.pendingBack = nil
        }
        pendingBack = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.doubleTapWindow, execute: work)
    }

    private func isDoubleTap() -> Bool {
        let now = Date()
        defer { lastTapAt = now }
        return now.timeIntervalSince(lastTapAt) < Self.doubleTapWindow
    }

    private func trigger(_ button: RemoteButton) {
        flash(button)
        let binding = bindings[button]
        guard permitToAct() else { return }

        if binding.action == .toggleScrollMode {
            scrollMode.toggle()
            appendLog(scrollMode ? "Scrolling on" : "Scrolling off")
            return
        }
        perform(binding)
    }

    /// Without Accessibility every injected event is silently dropped. The
    /// onboarding flow gates on the permission and the status pill reports it,
    /// so this only needs to keep the log honest.
    private func permitToAct() -> Bool {
        if accessibilityGranted { return true }
        guard Date().timeIntervalSince(lastPermissionNotice) > 30 else { return false }
        lastPermissionNotice = Date()
        appendLog("Ignored, Accessibility permission is not granted")
        return false
    }

    private func perform(_ binding: RemoteBinding) {
        controller.perform(binding.action,
                           shortcut: binding.shortcut,
                           sensitivity: pointerSensitivity)
    }

    private func flash(_ button: RemoteButton) {
        clearHighlightWork?.cancel()
        lastButton = button
        lastMappedAction = action(for: button)
        buttonEventCount += 1
        highlightedButton = button

        let work = DispatchWorkItem { [weak self] in
            self?.highlightedButton = nil
        }
        clearHighlightWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: work)
    }

    private static func loadBindings(from defaults: UserDefaults) -> RemoteBindings {
        guard let data = defaults.data(forKey: Keys.bindings),
              let overrides = try? JSONDecoder().decode(RemoteBindings.self, from: data)
        else { return .defaults }
        return .resolving(overrides)
    }

    private func saveBindings() {
        let overrides = bindings.overrides
        guard !overrides.bindings.isEmpty,
              let data = try? JSONEncoder().encode(overrides)
        else {
            defaults.removeObject(forKey: Keys.bindings)
            return
        }
        defaults.set(data, forKey: Keys.bindings)
    }

    private func appendLog(_ message: String) {
        logs.append(.init(date: Date(), message: message))
        if logs.count > 250 {
            logs.removeFirst(logs.count - 200)
        }
    }
}

/// What the user actually needs to know, in plain language. A live CEC link is
/// not enough on its own — without Accessibility the remote still does nothing,
/// so both are folded into one status rather than reported separately.
enum BridgeStatus: Equatable {
    case paused
    case needsPermission
    case waitingForRemote
    case ready
    case unsupported
    case failed(String)

    var title: String {
        switch self {
        case .paused: "Paused"
        case .needsPermission: "Needs Permission"
        case .waitingForRemote: "Waiting for Remote"
        case .ready: "Ready"
        case .unsupported: "Not Supported"
        case .failed: "Something Went Wrong"
        }
    }

    var detail: String {
        switch self {
        case .paused:
            "Remote control is turned off."
        case .needsPermission:
            "Allow Accessibility so the remote can move the pointer."
        case .waitingForRemote:
            "Connect this Mac to your TV over HDMI and turn on HDMI-CEC."
        case .ready:
            "Your TV remote is controlling this Mac."
        case .unsupported:
            "This Mac can't receive TV remote buttons."
        case .failed(let message):
            message
        }
    }

    var symbol: String {
        switch self {
        case .paused: "pause.circle.fill"
        case .needsPermission: "lock.fill"
        case .waitingForRemote: "cable.connector"
        case .ready: "checkmark.circle.fill"
        case .unsupported, .failed: "exclamationmark.triangle.fill"
        }
    }
}

extension BridgeModel {
    var status: BridgeStatus {
        switch connectionState {
        case .stopped: return .paused
        case .unsupported: return .unsupported
        case .failed(let message): return .failed(message)
        case .waitingForHDMI: return accessibilityGranted ? .waitingForRemote : .needsPermission
        case .running: return accessibilityGranted ? .ready : .needsPermission
        }
    }
}
