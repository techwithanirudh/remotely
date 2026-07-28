import Foundation

/// What a remote button does.
///
/// Actions used to be a bare enum stored as a raw string, which left nowhere to
/// put a recorded key combination. A binding pairs the action with whatever
/// payload that action needs, and is stored as JSON so adding a future payload
/// does not need another migration.
struct RemoteBinding: Codable, Hashable {
    var action: MacAction
    var shortcut: KeyboardShortcut?

    init(_ action: MacAction, shortcut: KeyboardShortcut? = nil) {
        self.action = action
        self.shortcut = shortcut
    }

    /// A shortcut binding is incomplete until something has been recorded.
    var isRunnable: Bool {
        action != .keyboardShortcut || shortcut != nil
    }

    var summary: String {
        guard action == .keyboardShortcut else { return action.title }
        return shortcut?.display ?? "Record…"
    }
}

extension MacAction: Codable {}

/// The full set of button bindings.
struct RemoteBindings: Codable, Hashable {
    var bindings: [RemoteButton: RemoteBinding]

    static let defaults = RemoteBindings(bindings: [
        .up: .init(.moveUp),
        .down: .init(.moveDown),
        .left: .init(.moveLeft),
        .right: .init(.moveRight),
        .center: .init(.leftClick),
        .centerDouble: .init(.doubleClick),
        .centerHold: .init(.rightClick),
        .back: .init(.escape),
        .doubleBack: .init(.toggleScrollMode),
    ])

    subscript(button: RemoteButton) -> RemoteBinding {
        get { bindings[button] ?? .init(.none) }
        set { bindings[button] = newValue }
    }

    func isDefault(_ button: RemoteButton) -> Bool {
        self[button] == Self.defaults[button]
    }

    /// Only what the user has changed.
    ///
    /// Persisting every binding froze whatever the defaults happened to be when
    /// the page was first opened, so later changing a default had no effect on
    /// anyone who had ever touched it.
    var overrides: RemoteBindings {
        RemoteBindings(bindings: bindings.filter { Self.defaults.bindings[$0.key] != $0.value })
    }

    /// Defaults with the user's overrides applied on top.
    static func resolving(_ overrides: RemoteBindings) -> RemoteBindings {
        var resolved = defaults
        for (button, binding) in overrides.bindings {
            resolved.bindings[button] = binding
        }
        return resolved
    }
}

extension RemoteButton: Codable {}
