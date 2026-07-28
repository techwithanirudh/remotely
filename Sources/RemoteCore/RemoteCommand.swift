import Foundation

/// The CEC User Control commands a TV actually forwards to a source device.
///
/// Media transport and volume are deliberately absent: displays handle those
/// internally and never put them on the CEC bus, so mapping them would ship
/// controls that can never fire.
public enum RemoteCommand: String, CaseIterable, Sendable {
    case up
    case down
    case left
    case right
    case select
    case back

    public var isDirectional: Bool {
        switch self {
        case .up, .down, .left, .right: true
        case .select, .back: false
        }
    }

    public var displayName: String {
        switch self {
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .select: "Select"
        case .back: "Back"
        }
    }
}
