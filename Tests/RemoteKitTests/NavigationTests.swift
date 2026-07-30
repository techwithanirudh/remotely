import CoreGraphics
import Foundation
import RemoteKit

func navigationTests() {
    Expect.suite("Back and Forward") {
        Expect.equal(NavigationMethod(frontmostApp: "com.microsoft.VSCode"), .mouseButton,
                     "VS Code ignores swipes, so it gets the mouse buttons")
        Expect.equal(NavigationMethod(frontmostApp: "com.apple.Safari"), .swipe,
                     "Apple apps ignore buttons 4 and 5 but take the swipe")
        Expect.equal(NavigationMethod(frontmostApp: "com.operasoftware.Opera"), .swipe,
                     "Opera is not an Apple app but wants the swipe")
        Expect.equal(NavigationMethod(frontmostApp: "com.apple.Notes"), .optionCommandBracket,
                     "plain Command-bracket indents in Notes")
        Expect.equal(NavigationMethod(frontmostApp: "com.apple.iCal"), .commandArrow,
                     "Command-bracket moves between occurrences in Calendar")
        Expect.equal(NavigationMethod(frontmostApp: "dev.warp.Warp"), .commandBracket,
                     "Warp is not an Apple app but wants the bracket")
        Expect.equal(NavigationMethod(frontmostApp: ""), .mouseButton,
                     "an unknown app gets the broadest method")
    }
}
