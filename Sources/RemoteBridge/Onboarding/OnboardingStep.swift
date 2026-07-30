import RemoteKit

enum OnboardingStep: Int, CaseIterable {
    case welcome, connect, permission
    case move, click, doubleClick, rightClick, scroll
    case finish

    @MainActor
    func isSatisfied(by bridge: RemoteBridge) -> Bool {
        switch self {
        case .permission: bridge.hasAccessibility
        default: true
        }
    }

    /// CEC can be unavailable, but Accessibility is required for the app to work.
    var isSkippable: Bool { self != .permission }
}
