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

    @Published private(set) var buttonMappings: [RemoteButton: MacAction]

    /// Name reported by the attached display's EDID, once CEC traffic is seen.
    @Published private(set) var displayName: String?

    @Published var cursorStep: Double {
        didSet { defaults.set(cursorStep, forKey: Keys.cursorStep) }
    }

    let client = CECClient()
    private let controller = MacController()
    private let defaults = UserDefaults.standard
    private var pendingBack: DispatchWorkItem?
    private var clearHighlightWork: DispatchWorkItem?
    private var heldCommand: RemoteCommand?
    private var heldSince = Date.distantPast
    private var lastTapAt = Date.distantPast

    private static let holdThreshold: TimeInterval = 0.5
    private static let doubleTapWindow: TimeInterval = 0.38

    private enum Keys {
        static let bridgeEnabled = "bridgeEnabled"
        static let cursorStep = "cursorStep"
        static let buttonMappings = "buttonMappings.v1"
    }

    init() {
        defaults.register(defaults: [
            Keys.bridgeEnabled: true,
            Keys.cursorStep: 42.0,
        ])
        bridgeEnabled = defaults.bool(forKey: Keys.bridgeEnabled)
        cursorStep = defaults.double(forKey: Keys.cursorStep)
        buttonMappings = Self.loadMappings(from: defaults)

        client.onStateChange = { [weak self] state in
            self?.connectionState = state
            self?.appendLog("Connection: \(state.displayName)")
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

    func test(_ action: MacAction) {
        appendLog("Test action: \(action.title)")
        controller.perform(action, cursorStep: cursorStep)
    }

    func action(for button: RemoteButton) -> MacAction {
        buttonMappings[button] ?? .none
    }

    func setAction(_ action: MacAction, for button: RemoteButton) {
        buttonMappings[button] = action
        saveMappings()
        appendLog("\(button.title) mapped to \(action.title)")
    }

    func resetMappings() {
        buttonMappings = .defaultRemoteMappings
        saveMappings()
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

        guard command != heldCommand else {
            if command.isDirectional { repeatDirectional(command) }
            return
        }

        finishHeldCommand(released: false)
        heldCommand = command
        heldSince = Date()
        appendLog("Button: \(command.displayName)")

        if command.isDirectional { repeatDirectional(command) }
    }

    private func receiveRelease() {
        finishHeldCommand(released: true)
    }

    private func repeatDirectional(_ command: RemoteCommand) {
        guard let button = RemoteButton(command: command) else { return }
        flash(button)
        perform(action(for: button))
    }

    private func finishHeldCommand(released: Bool) {
        guard let command = heldCommand else { return }
        heldCommand = nil
        guard released, !command.isDirectional else { return }

        let heldLongEnough = Date().timeIntervalSince(heldSince) >= Self.holdThreshold

        switch command {
        case .select:
            if heldLongEnough {
                trigger(.centerHold)
            } else {
                trigger(isDoubleTap() ? .centerDouble : .center)
            }
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
        perform(action(for: button))
    }

    private func perform(_ action: MacAction) {
        controller.perform(action, cursorStep: cursorStep)
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

    private static func loadMappings(from defaults: UserDefaults) -> [RemoteButton: MacAction] {
        guard let stored = defaults.dictionary(forKey: Keys.buttonMappings) as? [String: String] else {
            var mappings = [RemoteButton: MacAction].defaultRemoteMappings
            if defaults.object(forKey: "doubleBackShowsDesktop") != nil,
               !defaults.bool(forKey: "doubleBackShowsDesktop") {
                mappings[.doubleBack] = MacAction.none
            }
            return mappings
        }

        var mappings = [RemoteButton: MacAction].defaultRemoteMappings
        for (buttonValue, actionValue) in stored {
            guard let button = RemoteButton(rawValue: buttonValue),
                  let action = MacAction(rawValue: actionValue) else { continue }
            mappings[button] = action
        }
        return mappings
    }

    private func saveMappings() {
        let stored = Dictionary(
            uniqueKeysWithValues: buttonMappings.map { ($0.key.rawValue, $0.value.rawValue) }
        )
        defaults.set(stored, forKey: Keys.buttonMappings)
    }

    private func appendLog(_ message: String) {
        logs.append(.init(date: Date(), message: message))
        if logs.count > 250 {
            logs.removeFirst(logs.count - 200)
        }
    }
}

extension CECClient.State {
    var displayName: String {
        switch self {
        case .stopped: "Bridge Off"
        case .unsupported: "Native CEC Unavailable"
        case .waitingForHDMI: "Waiting for HDMI"
        case .running: "Connected"
        case .failed: "Connection Error"
        }
    }

    var detail: String {
        switch self {
        case .stopped: "Remote input is paused."
        case .unsupported: "CoreRC is not available on this version of macOS."
        case .waitingForHDMI: "Connect the M7 to the Mac mini’s built-in HDMI port."
        case .running: "The native HDMI-CEC bus is active and listening."
        case .failed(let message): message
        }
    }

    var symbol: String {
        switch self {
        case .stopped: "pause.circle.fill"
        case .unsupported, .failed: "exclamationmark.triangle.fill"
        case .waitingForHDMI: "cable.connector"
        case .running: "checkmark.circle.fill"
        }
    }
}
