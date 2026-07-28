import Foundation

public enum RemoteCommand: String, CaseIterable, Sendable {
    case up
    case down
    case left
    case right
    case select
    case back
    case home
    case playPause
    case play
    case pause
    case rewind
    case fastForward
    case volumeUp
    case volumeDown
    case mute
}

public struct CECLineParser: Sendable {
    public init() {}

    public func parse(_ line: String) -> RemoteCommand? {
        let normalized = line.lowercased()

        // libCEC's human-readable callback output. Act on presses, not releases,
        // so a tap is responsive and does not fire twice.
        if normalized.contains("key pressed:") {
            return namedKey(from: normalized.components(separatedBy: "key pressed:")[1])
        }

        // Raw CEC traffic fallback:
        //   0x44 = User Control Pressed, followed by the UI command byte.
        // This also makes dry-run diagnostics useful in monitor mode.
        if let range = normalized.range(
            of: #"(?:^|[^0-9a-f])(?:[0-9a-f]{2}:)?44:([0-9a-f]{2})(?:[^0-9a-f]|$)"#,
            options: .regularExpression
        ) {
            let match = String(normalized[range])
            let bytes = match
                .split(separator: ":")
                .compactMap { UInt8($0.filter(\.isHexDigit), radix: 16) }
            if let code = bytes.last {
                return rawCECKey(code)
            }
        }

        return nil
    }

    private func namedKey(from suffix: String) -> RemoteCommand? {
        let name = suffix
            .split(whereSeparator: { $0 == "(" || $0 == "[" })
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_") ?? ""

        switch name {
        case "up": return .up
        case "down": return .down
        case "left": return .left
        case "right": return .right
        case "select", "enter": return .select
        case "exit", "back", "return": return .back
        case "root menu", "root_menu", "home": return .home
        case "play/pause", "play_pause", "playpause": return .playPause
        case "play": return .play
        case "pause": return .pause
        case "rewind", "backward": return .rewind
        case "fast forward", "fast_forward", "forward": return .fastForward
        case "volume up", "volume_up": return .volumeUp
        case "volume down", "volume_down": return .volumeDown
        case "mute": return .mute
        default: return nil
        }
    }

    private func rawCECKey(_ code: UInt8) -> RemoteCommand? {
        switch code {
        case 0x00: return .select
        case 0x01: return .up
        case 0x02: return .down
        case 0x03: return .left
        case 0x04: return .right
        case 0x09: return .home
        case 0x0D: return .back
        case 0x20: return .playPause
        case 0x41: return .volumeUp
        case 0x42: return .volumeDown
        case 0x43: return .mute
        case 0x44: return .play
        case 0x45, 0x46: return .pause
        case 0x48: return .rewind
        case 0x49: return .fastForward
        default: return nil
        }
    }
}
