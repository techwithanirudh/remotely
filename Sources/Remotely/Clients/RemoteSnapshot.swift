import RemotelyKit

struct RemoteSnapshot: Equatable, Sendable {
    let status: RemoteStatus
    let displayName: String?
    let pressCount: UInt64
    let isScrolling: Bool
    let log: [RemoteLogEntry]
    let hasAccessibility: Bool
    let isEnabled: Bool
    let sensitivity: Double
    let bindings: Bindings
}
