// Derived from Mac Mouse Fix, under the MMF License rather than this
// repository's MIT: https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License

/// Per-app compatibility choices adapted from Mac Mouse Fix and verified here.
public enum NavigationMethod: Equatable, Sendable {
    case swipe
    case mouseButton
    case commandBracket
    case optionCommandBracket
    case commandArrow

    public init(targetApp bundleID: String) {
        if Self.matches(bundleID, "com.apple.Notes", "com.apple.freeform") {
            self = .optionCommandBracket
        } else if Self.matches(bundleID, "com.adobe.Acrobat.Pro", "com.apple.iCal") {
            self = .commandArrow
        } else if Self.matches(bundleID, "com.operasoftware.Opera", "com.binarynights.ForkLift") {
            self = .swipe
        } else if Self.matches(
            bundleID,
            "org.zotero.zotero",
            "dev.warp.Warp",
            "com.apple.systempreferences",
            "com.apple.AppStore",
            "com.apple.Music",
            "com.apple.AddressBook",
            "com.apple.TV",
            "com.apple.iBooksX",
            "com.apple.Preview",
            // Finder accepts Back swipes but not Forward swipes on macOS 26.
            "com.apple.finder"
        ) {
            self = .commandBracket
        } else {
            self = bundleID.hasPrefix("com.apple.") ? .swipe : .mouseButton
        }
    }

    public var title: String {
        switch self {
        case .swipe: "swipe"
        case .mouseButton: "mouse-button"
        case .commandBracket: "command-bracket"
        case .optionCommandBracket: "option-command-bracket"
        case .commandArrow: "command-arrow"
        }
    }

    private static func matches(_ bundleID: String, _ prefixes: String...) -> Bool {
        prefixes.contains { bundleID.hasPrefix($0) }
    }
}
