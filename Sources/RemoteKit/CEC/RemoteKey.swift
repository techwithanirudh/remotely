import Foundation

/// A key as CEC reports it.
///
/// Only these six ever arrive. Volume, media transport and Home never reach the
/// Mac: displays handle them internally and keep them off the bus entirely.
public enum RemoteKey: String, CaseIterable, Sendable {
    case up, down, left, right, select, back

    public var title: String {
        switch self {
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .select: "Select"
        case .back: "Back"
        }
    }

    public var isDirectional: Bool {
        switch self {
        case .up, .down, .left, .right: true
        case .select, .back: false
        }
    }

    /// The CEC User Control wire codes.
    init?(cecCode code: UInt8) {
        switch code {
        case 0x00: self = .select
        case 0x01: self = .up
        case 0x02: self = .down
        case 0x03: self = .left
        case 0x04: self = .right
        case 0x0D: self = .back
        default: return nil
        }
    }
}
