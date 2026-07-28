import Foundation

/// Where the first-run flow keeps its state.
///
/// Progress is persisted rather than held in memory because granting
/// Accessibility commonly involves quitting the app, and losing your place
/// every time you do that makes the flow feel broken.
enum OnboardingProgress {
    static let completedKey = "completedOnboarding"
    static let stepKey = "onboardingStep"
    static let brandKey = "onboardingBrand"

    private static let buildKey = "onboardingBuild"

    static var isComplete: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    /// Identifies the installed bundle. The version string does not change
    /// between local builds, so this uses the executable's modification date,
    /// which does.
    private static var installedBuild: String {
        guard let path = Bundle.main.executablePath,
              let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let modified = attributes[.modificationDate] as? Date
        else { return "unknown" }
        return String(Int(modified.timeIntervalSince1970))
    }

    /// Replaying the app bundle revokes Accessibility, because the ad-hoc
    /// signature changes with every build. Setup genuinely has to be redone, so
    /// a new build starts the flow over rather than resuming into a state that
    /// no longer holds.
    static func resetIfReinstalled() {
        let defaults = UserDefaults.standard
        let current = installedBuild
        guard defaults.string(forKey: buildKey) != current else { return }
        defaults.set(current, forKey: buildKey)
        replay()
    }

    static func markComplete() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    /// Starts the flow over from the first screen.
    static func replay() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: completedKey)
        defaults.set(0, forKey: stepKey)
    }
}
