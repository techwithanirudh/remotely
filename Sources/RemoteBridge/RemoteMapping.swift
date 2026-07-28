import Foundation
import RemoteCore

enum RemoteButton: String, CaseIterable, Identifiable {
    case up
    case down
    case left
    case right
    case center
    case back
    case doubleBack
    case playPause
    case rewind
    case fastForward
    case volumeUp
    case volumeDown
    case mute

    var id: Self { self }

    var title: String {
        switch self {
        case .up: "D-pad Up"
        case .down: "D-pad Down"
        case .left: "D-pad Left"
        case .right: "D-pad Right"
        case .center: "Center"
        case .back: "Back"
        case .doubleBack: "Double Back"
        case .playPause: "Play / Pause"
        case .rewind: "Rewind"
        case .fastForward: "Fast Forward"
        case .volumeUp: "Volume Up"
        case .volumeDown: "Volume Down"
        case .mute: "Mute"
        }
    }

    var symbol: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .center: "circle.inset.filled"
        case .back: "arrow.uturn.backward"
        case .doubleBack: "arrow.uturn.backward.circle"
        case .playPause: "playpause.fill"
        case .rewind: "backward.fill"
        case .fastForward: "forward.fill"
        case .volumeUp: "speaker.plus.fill"
        case .volumeDown: "speaker.minus.fill"
        case .mute: "speaker.slash.fill"
        }
    }

    init?(command: RemoteCommand) {
        switch command {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .select: self = .center
        case .back: self = .back
        case .playPause, .play, .pause: self = .playPause
        case .rewind: self = .rewind
        case .fastForward: self = .fastForward
        case .volumeUp: self = .volumeUp
        case .volumeDown: self = .volumeDown
        case .mute: self = .mute
        case .home: return nil
        }
    }
}

enum MacAction: String, CaseIterable, Identifiable {
    case none
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    case leftClick
    case browserBack
    case showDesktop
    case playPause
    case rewind
    case fastForward
    case volumeUp
    case volumeDown
    case mute

    var id: Self { self }

    var title: String {
        switch self {
        case .none: "Do Nothing"
        case .moveUp: "Move Pointer Up"
        case .moveDown: "Move Pointer Down"
        case .moveLeft: "Move Pointer Left"
        case .moveRight: "Move Pointer Right"
        case .leftClick: "Left Click"
        case .browserBack: "Browser Back"
        case .showDesktop: "Show Desktop"
        case .playPause: "Play / Pause"
        case .rewind: "Previous / Rewind"
        case .fastForward: "Next / Fast Forward"
        case .volumeUp: "Volume Up"
        case .volumeDown: "Volume Down"
        case .mute: "Mute"
        }
    }

    var symbol: String {
        switch self {
        case .none: "nosign"
        case .moveUp: "arrow.up"
        case .moveDown: "arrow.down"
        case .moveLeft: "arrow.left"
        case .moveRight: "arrow.right"
        case .leftClick: "cursorarrow.click"
        case .browserBack: "chevron.backward"
        case .showDesktop: "macwindow"
        case .playPause: "playpause.fill"
        case .rewind: "backward.fill"
        case .fastForward: "forward.fill"
        case .volumeUp: "speaker.plus.fill"
        case .volumeDown: "speaker.minus.fill"
        case .mute: "speaker.slash.fill"
        }
    }
}

extension Dictionary where Key == RemoteButton, Value == MacAction {
    static var defaultRemoteMappings: Self {
        [
            .up: .moveUp,
            .down: .moveDown,
            .left: .moveLeft,
            .right: .moveRight,
            .center: .leftClick,
            .back: .browserBack,
            .doubleBack: .showDesktop,
            .playPause: .playPause,
            .rewind: .rewind,
            .fastForward: .fastForward,
            .volumeUp: .volumeUp,
            .volumeDown: .volumeDown,
            .mute: .mute,
        ]
    }
}
