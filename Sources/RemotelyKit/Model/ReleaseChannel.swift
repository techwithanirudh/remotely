import Defaults

/// Which releases the updater will offer.
public enum ReleaseChannel: String, CaseIterable, Identifiable, Defaults.Serializable, Sendable {
    case stable, beta

    public var id: Self { self }

    public var title: String {
        switch self {
        case .stable: "Stable"
        case .beta: "Beta"
        }
    }

    /// Sparkle reads an appcast entry with no channel as belonging to everyone,
    /// so stable is the empty set rather than a named channel.
    public var allowedChannels: Set<String> {
        switch self {
        case .stable: []
        case .beta: ["beta"]
        }
    }
}
