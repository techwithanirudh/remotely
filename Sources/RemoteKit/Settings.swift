import Defaults
import Foundation

extension Defaults.Keys {
    public static let enabled = Key<Bool>("enabled", default: true)
    public static let pointerSensitivity = Key<Double>("pointerSensitivity", default: 1)

    /// Only what the user has changed; defaults are applied on top at load.
    public static let bindings = Key<Bindings>("bindings", default: Bindings())

    public static let tvBrand = Key<TVBrand>("tvBrand", default: .samsung)

    public static let onboardingDone = Key<Bool>("onboardingDone", default: false)
    public static let onboardingStep = Key<Int>("onboardingStep", default: 0)
    /// Identifies the installed build, so a reinstall can restart setup.
    public static let installedBuild = Key<String>("installedBuild", default: "")
}

extension Bindings: Defaults.Serializable {}
extension TVBrand: Defaults.Serializable {}
