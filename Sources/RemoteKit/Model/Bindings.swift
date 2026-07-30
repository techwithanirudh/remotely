public struct ButtonBinding: Codable, Hashable, Sendable {
    public var action: RemoteAction
    public var combo: KeyCombo?

    public init(_ action: RemoteAction, combo: KeyCombo? = nil) {
        self.action = action
        self.combo = combo
    }

    public var isComplete: Bool {
        action != .keyboardShortcut || combo != nil
    }

    public var summary: String {
        guard action == .keyboardShortcut else { return action.title }
        return combo?.display ?? "Not set"
    }
}

/// Only what differs from `.standard` is persisted, so changing a default still
/// reaches anyone who has customized something else.
public struct Bindings: Codable, Hashable, Sendable {
    public private(set) var byButton: [RemoteButton: ButtonBinding]

    public init(_ byButton: [RemoteButton: ButtonBinding] = [:]) {
        self.byButton = byButton
    }

    public static let standard = Bindings([
        .up: ButtonBinding(.moveUp),
        .down: ButtonBinding(.moveDown),
        .left: ButtonBinding(.moveLeft),
        .right: ButtonBinding(.moveRight),
        .center: ButtonBinding(.leftClick),
        .centerDouble: ButtonBinding(.doubleClick),
        .centerHold: ButtonBinding(.rightClick),
        .back: ButtonBinding(.browserBack),
        .backDouble: ButtonBinding(.toggleScrolling),
        .backHold: ButtonBinding(.browserForward),
    ])

    public subscript(button: RemoteButton) -> ButtonBinding {
        get { byButton[button] ?? ButtonBinding(.none) }
        set { byButton[button] = newValue }
    }

    public func isStandard(_ button: RemoteButton) -> Bool {
        self[button] == Self.standard[button]
    }

    public var customized: Bindings {
        Bindings(byButton.filter { Self.standard.byButton[$0.key] != $0.value })
    }

    public static func resolving(_ customized: Bindings) -> Bindings {
        var result = standard
        for (button, binding) in customized.byButton {
            result.byButton[button] = binding
        }
        return result
    }
}
