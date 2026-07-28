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

    /// CoreRC's user-control codes.
    init?(coreRCCode code: UInt64) {
        switch code {
        case 1: self = .select
        case 2: self = .up
        case 3: self = .down
        case 4: self = .left
        case 5: self = .right
        case 13, 14: self = .back
        default: return nil
        }
    }
}
