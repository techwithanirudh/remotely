import Defaults

public extension Defaults.Keys {
    static let enabled = Key<Bool>("enabled", default: true)
    static let pointerSensitivity = Key<Double>("pointerSensitivity", default: 1)
    static let wantsBetaUpdates = Key<Bool>("wantsBetaUpdates", default: false)
    static let checksForUpdatesAutomatically = Key<Bool>(
        "checksForUpdatesAutomatically", default: true
    )
    /// Off until an update is observed to survive with the Accessibility grant
    /// intact. Installing one replaces the bundle, and if the grant does not
    /// carry over the remote goes dead with no visible cause.
    static let installsUpdatesAutomatically = Key<Bool>(
        "installsUpdatesAutomatically", default: false
    )

    /// Only what the user has changed; defaults are applied on top at load.
    static let bindings = Key<Bindings>("bindings", default: Bindings())

    static let tvBrand = Key<TVBrand>("tvBrand", default: .samsung)

    static let onboardingDone = Key<Bool>("onboardingDone", default: false)
    static let onboardingStep = Key<Int>("onboardingStep", default: 0)
}

extension Bindings: Defaults.Serializable {}
extension TVBrand: Defaults.Serializable {}
