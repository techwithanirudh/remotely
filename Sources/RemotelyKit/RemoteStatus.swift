/// A live CEC link is not enough on its own: without Accessibility the remote's
/// presses arrive and nothing happens, which looks identical to a dead remote.
/// Reporting the two separately made "Connected" a lie.
public enum RemoteStatus: Equatable, Sendable {
    case paused
    case needsPermission
    case noDisplay
    case waitingForRemote
    case ready
    case unsupported
    case failed(String)

    public var title: String {
        switch self {
        case .paused: "Paused"
        case .needsPermission: "Needs Permission"
        case .noDisplay: "No Display"
        case .waitingForRemote: "Waiting for Remote"
        case .ready: "Ready"
        case .unsupported: "Not Supported"
        case .failed: "Something Went Wrong"
        }
    }

    public var detail: String {
        switch self {
        case .paused: "Remote control is turned off."
        case .needsPermission: "Click to allow Accessibility, so the remote can move the pointer."
        case .noDisplay: "Connect this Mac to a display over HDMI."
        case .waitingForRemote: "Connected. Press a button on the remote to confirm."
        case .ready: "Your remote is controlling this Mac."
        case .unsupported: "This Mac has no HDMI port that carries remote buttons."
        case .failed(let message): message
        }
    }

    public var symbol: String {
        switch self {
        case .paused: "pause.circle.fill"
        case .needsPermission: "lock.fill"
        case .noDisplay: "cable.connector"
        case .waitingForRemote: "dot.radiowaves.left.and.right"
        case .ready: "checkmark.circle.fill"
        case .unsupported, .failed: "exclamationmark.triangle.fill"
        }
    }

    public var isReady: Bool { self == .ready }

    public init(link: CECLink.State, hasAccessibility: Bool, hasDisplay: Bool) {
        switch link {
        case .stopped: self = .paused
        case .unsupported: self = .unsupported
        case .failed(let message): self = .failed(message)
        case .waitingForDisplay:
            guard hasAccessibility else {
                self = .needsPermission
                return
            }
            self = hasDisplay ? .waitingForRemote : .noDisplay
        case .listening: self = hasAccessibility ? .ready : .needsPermission
        }
    }
}
