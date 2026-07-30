/// CEC reports only five keys. Everything past `back` is derived from timing,
/// because the wire has no concept of a double tap or a hold.
public enum RemoteButton: String, CaseIterable, Identifiable, Codable, Sendable {
    case up, down, left, right
    case center, centerDouble, centerHold
    case back, backDouble, backHold

    public var id: Self { self }

    public var title: String {
        switch self {
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .center: "Center"
        case .centerDouble: "Center twice"
        case .centerHold: "Center held"
        case .back: "Back"
        case .backDouble: "Back twice"
        case .backHold: "Back held"
        }
    }

    /// Short form for the Controls page, where the section heading already
    /// names the button.
    public var shortTitle: String {
        switch self {
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .center, .back: "Press"
        case .centerDouble, .backDouble: "Press twice"
        case .centerHold, .backHold: "Hold"
        }
    }

    public var symbol: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .center: "circle.inset.filled"
        case .centerDouble: "circle.circle.fill"
        case .centerHold: "hand.tap.fill"
        case .back: "arrow.uturn.backward"
        case .backDouble: "arrow.uturn.backward.circle"
        case .backHold: "hand.tap.fill"
        }
    }

    public init?(key: RemoteKey) {
        switch key {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .select: self = .center
        case .back: self = .back
        }
    }
}
