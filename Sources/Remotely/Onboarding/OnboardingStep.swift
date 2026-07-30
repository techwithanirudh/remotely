import RemotelyKit

enum OnboardingStep: Int, CaseIterable {
    case welcome, connect, permission
    case move, click, doubleClick, rightClick, scroll
    case finish

    @MainActor
    func isSatisfied(by remote: Remote) -> Bool {
        switch self {
        case .permission: remote.hasAccessibility
        default: true
        }
    }

    /// CEC can be unavailable, but Accessibility is required for the app to work.
    var isSkippable: Bool { self != .permission }
}
