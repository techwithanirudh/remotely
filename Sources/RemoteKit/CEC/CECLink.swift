import Foundation
import ObjectiveC.runtime

/// Receives remote presses over HDMI-CEC.
///
/// macOS ships CoreRC and the IOCECFamily driver, and turns incoming CEC user
/// control messages into HID events. Nothing about that is public API, so this
/// goes through the Objective-C runtime rather than private headers, which
/// keeps the project building against the ordinary SDK.
@MainActor
public final class CECLink {
    public enum State: Equatable, Sendable {
        case stopped
        case unsupported
        case waitingForDisplay
        case listening
        case failed(String)
    }

    public var onStateChange: ((State) -> Void)?
    public var onPress: ((RemoteKey) -> Void)?
    public var onRelease: (() -> Void)?
    public var onDisplayName: ((String) -> Void)?
    public var onLog: ((String) -> Void)?

    private var framework: UnsafeMutableRawPointer?
    private var manager: NSObject?
    private var pollTimer: Timer?
    private var attached = Set<ObjectIdentifier>()
    private var state: State?

    public init() {}

    public func start() {
        stop()

        guard let handle = dlopen(Self.frameworkPath, RTLD_NOW) else {
            transition(to: .unsupported)
            return
        }
        framework = handle

        guard let managerClass = NSClassFromString("CoreRCManager") as? NSObject.Type else {
            transition(to: .unsupported)
            return
        }

        let manager = managerClass.init()
        manager.setValue(self, forKey: "delegate")
        self.manager = manager

        poll()
        // CoreRC does not always announce a bus that appears after launch.
        pollTimer = .scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
    }

    public func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        manager?.perform(NSSelectorFromString("invalidate"))
        manager = nil
        attached.removeAll()

        if let framework {
            dlclose(framework)
            self.framework = nil
        }
        transition(to: .stopped)
    }
}

private extension CECLink {
    static let frameworkPath = "/System/Library/PrivateFrameworks/CoreRC.framework/CoreRC"

    func poll() {
        guard let manager else { return }
        let buses = objects(manager.value(forKey: "buses"))
        buses.forEach(attach(bus:))
        transition(to: buses.isEmpty ? .waitingForDisplay : .listening)
    }

    func attach(bus: NSObject) {
        if attached.insert(ObjectIdentifier(bus)).inserted {
            bus.setValue(self, forKey: "delegate")
        }
        objects(bus.value(forKey: "devices")).forEach(attach(device:))
    }

    func attach(device: NSObject) {
        guard attached.insert(ObjectIdentifier(device)).inserted else { return }
        device.setValue(self, forKey: "delegate")

        if let name = device.value(forKey: "name") as? String, !name.isEmpty {
            onDisplayName?(name)
        }
    }

    func objects(_ value: Any?) -> [NSObject] {
        switch value {
        case let set as NSSet: set.compactMap { $0 as? NSObject }
        case let array as NSArray: array.compactMap { $0 as? NSObject }
        default: []
        }
    }

    func transition(to next: State) {
        guard next != state else { return }
        state = next
        onStateChange?(next)
    }

    /// CoreRC hands the code and press flag back through out-parameters, so the
    /// method has to be called through its raw implementation.
    func decode(_ event: NSObject) -> (key: RemoteKey, isPress: Bool)? {
        let selector = NSSelectorFromString("getCommand:pressed:")
        guard event.responds(to: selector) else { return nil }

        typealias GetCommand = @convention(c) (
            AnyObject, Selector, UnsafeMutablePointer<UInt64>, UnsafeMutablePointer<ObjCBool>
        ) -> Void

        var code: UInt64 = 0
        var pressed = ObjCBool(false)
        let implementation = unsafeBitCast(event.method(for: selector), to: GetCommand.self)
        implementation(event, selector, &code, &pressed)

        guard let key = RemoteKey(coreRCCode: code) else {
            onLog?("Unmapped CEC code \(code)")
            return nil
        }
        return (key, pressed.boolValue)
    }
}

// MARK: - CoreRC delegate callbacks

extension CECLink {
    @objc(manager:hasAdded:)
    func manager(_ manager: AnyObject, hasAdded bus: AnyObject) {
        guard let bus = bus as? NSObject else { return }
        attach(bus: bus)
        transition(to: .listening)
    }

    @objc(manager:hasRemoved:)
    func manager(_ manager: AnyObject, hasRemoved bus: AnyObject) { poll() }

    @objc(manager:hasUpdated:)
    func manager(_ manager: AnyObject, hasUpdated bus: AnyObject) { poll() }

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
    func bus(_ bus: AnyObject, deviceHasBeenRemoved device: AnyObject) { poll() }

    @objc(device:receivedHIDEvent:fromDevice:)
    func device(_ device: AnyObject, receivedHIDEvent event: AnyObject, fromDevice source: AnyObject) {
        guard let event = event as? NSObject, let decoded = decode(event) else { return }

        if decoded.isPress {
            onPress?(decoded.key)
        } else {
            onRelease?()
        }
    }
}
