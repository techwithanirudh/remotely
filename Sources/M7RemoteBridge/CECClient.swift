import Foundation
import ObjectiveC.runtime
import M7RemoteCore

/// Zero-cost CEC receiver for M4 Macs.
///
/// Apple ships the private CoreRC framework and IOCECFamily driver with macOS.
/// The M4 Mac mini's built-in HDMI port is an officially supported CEC link.
/// CoreRC turns incoming CEC User Control messages into CoreRCHIDEvent objects.
///
/// This deliberately uses Objective-C runtime calls instead of private headers,
/// so the project still builds with the normal Command Line Tools SDK.
@MainActor
final class CECClient: NSObject {
    enum State: Equatable {
        case stopped
        case unsupported
        case waitingForHDMI
        case running
        case failed(String)
    }

    var onStateChange: ((State) -> Void)?
    var onCommand: ((RemoteCommand) -> Void)?
    var onLog: ((String) -> Void)?

    private var frameworkHandle: UnsafeMutableRawPointer?
    private var manager: NSObject?
    private var refreshTimer: Timer?
    private var attachedBusIDs = Set<ObjectIdentifier>()
    private var attachedDeviceIDs = Set<ObjectIdentifier>()
    private var lastState: State?

    func start() {
        stop()

        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/CoreRC.framework/CoreRC",
            RTLD_NOW
        ) else {
            setState(.unsupported)
            return
        }
        frameworkHandle = handle

        guard let managerClass = NSClassFromString("CoreRCManager") as? NSObject.Type else {
            setState(.unsupported)
            return
        }

        let manager = managerClass.init()
        manager.setValue(self, forKey: "delegate")
        self.manager = manager

        refresh()
        refreshTimer = .scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        manager?.perform(NSSelectorFromString("invalidate"))
        manager = nil
        attachedBusIDs.removeAll()
        attachedDeviceIDs.removeAll()
        if let frameworkHandle {
            dlclose(frameworkHandle)
            self.frameworkHandle = nil
        }
        setState(.stopped)
    }

    private func refresh() {
        guard let manager else { return }
        let buses = objects(from: manager.value(forKey: "buses"))
        for bus in buses {
            attach(bus: bus)
        }
        setState(buses.isEmpty ? .waitingForHDMI : .running)
    }

    private func attach(bus: NSObject) {
        let identifier = ObjectIdentifier(bus)
        if attachedBusIDs.insert(identifier).inserted {
            bus.setValue(self, forKey: "delegate")
            onLog?("CEC bus added: \(bus)")
        }
        for device in objects(from: bus.value(forKey: "devices")) {
            attach(device: device)
        }
    }

    private func attach(device: NSObject) {
        let identifier = ObjectIdentifier(device)
        guard attachedDeviceIDs.insert(identifier).inserted else { return }
        device.setValue(self, forKey: "delegate")
        onLog?("CEC device added: \(device)")
    }

    private func objects(from value: Any?) -> [NSObject] {
        if let set = value as? NSSet {
            return set.compactMap { $0 as? NSObject }
        }
        if let array = value as? NSArray {
            return array.compactMap { $0 as? NSObject }
        }
        return []
    }

    private func decode(event: NSObject) -> (command: RemoteCommand, pressed: Bool)? {
        let selector = NSSelectorFromString("getCommand:pressed:")
        guard event.responds(to: selector) else { return nil }

        typealias GetCommand = @convention(c) (
            AnyObject,
            Selector,
            UnsafeMutablePointer<UInt64>,
            UnsafeMutablePointer<ObjCBool>
        ) -> Void

        var rawCommand: UInt64 = 0
        var pressed = ObjCBool(false)
        let implementation = event.method(for: selector)
        let getCommand = unsafeBitCast(implementation, to: GetCommand.self)
        getCommand(event, selector, &rawCommand, &pressed)

        guard let command = map(rawCommand) else {
            onLog?("Unmapped CoreRC command \(rawCommand), pressed=\(pressed.boolValue)")
            return nil
        }
        return (command, pressed.boolValue)
    }

    private func map(_ command: UInt64) -> RemoteCommand? {
        switch command {
        case 1: return .select
        case 2: return .up
        case 3: return .down
        case 4: return .left
        case 5: return .right
        case 10: return .home
        case 14: return .back
        case 43: return .volumeUp
        case 44: return .volumeDown
        case 45: return .mute
        case 46: return .playPause
        case 47, 69: return .pause
        case 48: return .rewind
        case 49: return .fastForward
        case 67: return .play
        default: return nil
        }
    }

    private func setState(_ state: State) {
        guard state != lastState else { return }
        lastState = state
        onStateChange?(state)
    }

    // MARK: CoreRCManagerDelegate

    @objc(manager:hasAdded:)
    func manager(_ manager: AnyObject, hasAdded bus: AnyObject) {
        guard let bus = bus as? NSObject else { return }
        attach(bus: bus)
        setState(.running)
    }

    @objc(manager:hasRemoved:)
    func manager(_ manager: AnyObject, hasRemoved bus: AnyObject) {
        refresh()
    }

    @objc(manager:hasUpdated:)
    func manager(_ manager: AnyObject, hasUpdated bus: AnyObject) {
        refresh()
    }

    // MARK: CoreRCBusDelegate

    @objc(bus:deviceHasBeenAdded:)
    func bus(_ bus: AnyObject, deviceHasBeenAdded device: AnyObject) {
        guard let device = device as? NSObject else { return }
        attach(device: device)
    }

    @objc(bus:deviceHasBeenUpdated:)
    func bus(_ bus: AnyObject, deviceHasBeenUpdated device: AnyObject) {
        guard let device = device as? NSObject else { return }
        attach(device: device)
    }

    @objc(bus:deviceHasBeenRemoved:)
    func bus(_ bus: AnyObject, deviceHasBeenRemoved device: AnyObject) {
        refresh()
    }

    // MARK: CoreRCDeviceDelegate

    @objc(device:receivedHIDEvent:fromDevice:)
    func device(
        _ device: AnyObject,
        receivedHIDEvent event: AnyObject,
        fromDevice source: AnyObject
    ) {
        guard
            let event = event as? NSObject,
            let decoded = decode(event: event)
        else { return }

        onLog?("CoreRC: \(decoded.command.rawValue), pressed=\(decoded.pressed)")
        if decoded.pressed {
            onCommand?(decoded.command)
        }
    }
}
