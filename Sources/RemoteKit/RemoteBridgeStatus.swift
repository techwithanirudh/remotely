import Foundation

/// What the user needs to know, in one value.
///
/// A live CEC link is not enough on its own: without Accessibility the remote's
/// presses arrive and nothing happens, which looks identical to a dead remote.
/// Reporting the two separately made "Connected" a lie.
public enum BridgeStatus: Equatable, Sendable {
    case paused
    case needsPermission
    case waitingForRemote
    case ready
    case unsupported
    case failed(String)

    public var title: String {
        switch self {
        case .paused: "Paused"
        case .needsPermission: "Needs Permission"
        case .waitingForRemote: "Waiting for Remote"
        case .ready: "Ready"
        case .unsupported: "Not Supported"
        case .failed: "Something Went Wrong"
        }
    }

    public var detail: String {
        switch self {
        case .paused: "Remote control is turned off."
        case .needsPermission: "Allow Accessibility so the remote can move the pointer."
        case .waitingForRemote: "Connect this Mac to your TV over HDMI and turn on HDMI-CEC."
        case .ready: "Your TV remote is controlling this Mac."
        case .unsupported: "This Mac can't receive TV remote buttons."
        case .failed(let message): message
        }
    }

    public var symbol: String {
        switch self {
        case .paused: "pause.circle.fill"
        case .needsPermission: "lock.fill"
        case .waitingForRemote: "cable.connector"
        case .ready: "checkmark.circle.fill"
        case .unsupported, .failed: "exclamationmark.triangle.fill"
        }
    }

    public var isReady: Bool { self == .ready }

    public init(link: CECLink.State, hasAccessibility: Bool) {
        switch link {
        case .stopped: self = .paused
        case .unsupported: self = .unsupported
        case .failed(let message): self = .failed(message)
        case .waitingForDisplay: self = hasAccessibility ? .waitingForRemote : .needsPermission
        case .listening: self = hasAccessibility ? .ready : .needsPermission
        }
    }
}
