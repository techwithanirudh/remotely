enum OnboardingStep: Int, CaseIterable, Equatable, Sendable {
    case welcome, connect, permission
    case move, click, doubleClick, rightClick, scroll
    case finish

    func isSatisfied(hasAccessibility: Bool) -> Bool {
        switch self {
        case .permission: hasAccessibility
        default: true
        }
    }

    /// CEC can be unavailable, but Accessibility is required for the app to work.
    var isSkippable: Bool { self != .permission }
}
