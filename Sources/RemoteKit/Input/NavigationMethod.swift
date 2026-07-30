// Derived from Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix),
// which is under the MMF License, not MIT like the rest of this repository:
// https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License
//
// Its conditions attach to publishing a program whose source is copied or
// derived from theirs, so read it before this app is distributed.

import Foundation

/// How the frontmost app expects to be told to go back.
///
/// There is no single answer. Mac Mouse Fix tested about forty apps and wrote
/// the results up in `Universal Back and Forward.md`: buttons 4 and 5 are
/// ignored by Apple's own apps, and the swipe gesture those respond to is
/// ignored by VS Code and its forks. This is their table, reimplemented — the
/// app list is their finding, the code is not theirs to copy.
///
/// Their fourth method, a navigation swipe, needs a private touch API we do
/// not have, so apps that want one get Command-bracket instead.
///
/// Their two fallbacks are not ours. A mouse button is the right guess when the
/// press came from a mouse that has one, but this app has no such button to
/// forward, and every app outside their table simply ignored it. The swipe is
/// an ordinary CGEvent carrying undocumented gesture fields, which any other
/// global listener sees too. Command-bracket is the one that works nearly
/// everywhere, so unknown apps get that and the other two are left to the apps
/// their table names.
public enum NavigationMethod: Equatable, Sendable {
    case swipe
    case commandBracket
    case optionCommandBracket
    case commandArrow

    public init(frontmostApp bundleID: String) {
        switch bundleID {
        case "com.apple.Notes", "com.apple.freeform":
            self = .optionCommandBracket
        case "com.adobe.Acrobat.Pro", "com.apple.iCal":
            self = .commandArrow
        case "com.operasoftware.Opera", "com.binarynights.ForkLift":
            self = .swipe
        default:
            self = .commandBracket
        }
    }

    public var title: String {
        switch self {
        case .swipe: "swipe"
        case .commandBracket: "command-bracket"
        case .optionCommandBracket: "option-command-bracket"
        case .commandArrow: "command-arrow"
        }
    }
}
