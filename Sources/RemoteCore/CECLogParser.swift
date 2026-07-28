import Foundation

/// Parses `corercd` unified-log lines into remote events.
///
/// Two line shapes matter:
///   `... RX: TV -> Playback Device 1: <User Control Pressed> 02`
///   `... CECBus <...> Link: Y; ... EDID: <CECEDIDAttributes: 0x...> Smart M70D vID: ...`
///
/// The raw User Control byte is used rather than the daemon's English button
/// names because it is the actual CEC wire code, and because the daemon repeats
/// it while a key is held — which is what drives pointer acceleration.
public struct CECLogParser: Sendable {
    public enum Event: Equatable, Sendable {
        case pressed(RemoteCommand)
        /// CEC releases carry no key code — only one key is ever held at a time.
        case released
        case attached(String)
    }

    public init() {}

    public func parse(_ line: String) -> Event? {
        if let code = userControlCode(in: line) {
            return rawCECKey(code).map(Event.pressed)
        }
        if line.contains("<User Control Released>") {
            return .released
        }
        if line.contains("Link: Y"), let display = displayName(in: line) {
            return .attached(display)
        }
        return nil
    }

    private func userControlCode(in line: String) -> UInt8? {
        let marker = "<User Control Pressed> "
        guard let range = line.range(of: marker) else { return nil }
        let hex = line[range.upperBound...].prefix(2)
        return UInt8(hex, radix: 16)
    }

    private func displayName(in line: String) -> String? {
        guard let edid = line.range(of: "EDID: <CECEDIDAttributes") else { return nil }
        let afterMarker = line[edid.upperBound...]
        guard let objectEnd = afterMarker.range(of: "> ") else { return nil }
        let rest = afterMarker[objectEnd.upperBound...]
        guard let vendor = rest.range(of: " vID:") else { return nil }
        let name = rest[rest.startIndex..<vendor.lowerBound]
            .trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    private func rawCECKey(_ code: UInt8) -> RemoteCommand? {
        switch code {
        case 0x00: return .select
        case 0x01: return .up
        case 0x02: return .down
        case 0x03: return .left
        case 0x04: return .right
        case 0x0D: return .back
        default: return nil
        }
    }
}
