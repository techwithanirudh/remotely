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
public enum NavigationMethod: Equatable, Sendable {
    case swipe
    case mouseButton
    case commandBracket
    case optionCommandBracket
    case commandArrow

    public init(frontmostApp bundleID: String) {
        switch bundleID {
        case "com.apple.Notes", "com.apple.freeform":
            self = .optionCommandBracket
        case "com.adobe.Acrobat.Pro", "com.apple.iCal":
            self = .commandArrow
        case "org.zotero.zotero", "dev.warp.Warp",
             "com.apple.systempreferences", "com.apple.AppStore",
             "com.apple.Music", "com.apple.AddressBook",
             "com.apple.TV", "com.apple.iBooksX", "com.apple.Preview":
            self = .commandBracket
        case "com.operasoftware.Opera", "com.binarynights.ForkLift":
            self = .swipe
        default:
            // Apple apps ignore buttons 4 and 5 entirely.
            self = bundleID.hasPrefix("com.apple.") ? .swipe : .mouseButton
        }
    }
}
