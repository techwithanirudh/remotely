/// A key as CEC reports it. Volume, media and Home never reach the Mac.
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

    var isDirectional: Bool {
        switch self {
        case .up, .down, .left, .right: true
        case .select, .back: false
        }
    }

    /// The CEC User Control wire codes.
    ///
    /// The display reports tap and hold as different codes. Measured on a
    /// Hisense M70D: 0x0D always spans 0.070-0.072s whatever the finger does,
    /// 0x2C spans 0.875-1.729s. Both are Back.
    init?(cecCode code: UInt8) {
        switch code {
        case 0x00: self = .select
        case 0x01: self = .up
        case 0x02: self = .down
        case 0x03: self = .left
        case 0x04: self = .right
        case 0x0D, 0x2C: self = .back
        default: return nil
        }
    }
}
