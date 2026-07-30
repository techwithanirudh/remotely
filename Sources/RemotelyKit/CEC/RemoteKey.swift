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
    ///
    /// The display decides tap from hold itself and reports them as different
    /// codes. Measured over 36 presses on a Hisense M70D: 0x0D always spans
    /// 0.070-0.072s whatever the finger does, while 0x2C spans 0.875-1.729s and
    /// tracks the real press. Both are Back, so the duration between press and
    /// release is what separates a tap from a hold, and dropping 0x2C as
    /// unknown is what made holding Back do nothing.
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
