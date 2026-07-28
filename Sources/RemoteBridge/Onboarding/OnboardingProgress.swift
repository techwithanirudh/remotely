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

    static var isComplete: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
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
