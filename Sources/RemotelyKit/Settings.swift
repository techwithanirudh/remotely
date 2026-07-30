import Defaults

public extension Defaults.Keys {
    static let enabled = Key<Bool>("enabled", default: true)
    static let pointerSensitivity = Key<Double>("pointerSensitivity", default: 1)
    static let wantsBetaUpdates = Key<Bool>("wantsBetaUpdates", default: false)
    static let checksForUpdatesAutomatically = Key<Bool>(
        "checksForUpdatesAutomatically", default: true
    )

    /// Only what the user has changed; defaults are applied on top at load.
    static let bindings = Key<Bindings>("bindings", default: Bindings())

    static let tvBrand = Key<TVBrand>("tvBrand", default: .samsung)

    static let onboardingDone = Key<Bool>("onboardingDone", default: false)
    static let onboardingStep = Key<Int>("onboardingStep", default: 0)
}

extension Bindings: Defaults.Serializable {}
extension TVBrand: Defaults.Serializable {}
