import CoreGraphics
import Foundation
import RemoteKit

func navigationTests() {
    Expect.suite("Back and Forward") {
        Expect.equal(NavigationMethod(frontmostApp: "com.microsoft.VSCode"), .commandBracket,
                     "VS Code ignores swipes")
        Expect.equal(NavigationMethod(frontmostApp: "com.apple.Safari"), .commandBracket,
                     "Apple apps ignore buttons 4 and 5")
        Expect.equal(NavigationMethod(frontmostApp: "com.operasoftware.Opera"), .swipe,
                     "Opera takes only the swipe")
        Expect.equal(NavigationMethod(frontmostApp: "com.apple.Notes"), .optionCommandBracket,
                     "plain Command-bracket indents in Notes")
        Expect.equal(NavigationMethod(frontmostApp: "com.apple.iCal"), .commandArrow,
                     "Command-bracket moves between occurrences in Calendar")
        Expect.equal(NavigationMethod(frontmostApp: "dev.warp.Warp"), .commandBracket,
                     "Warp takes the bracket")
        Expect.equal(NavigationMethod(frontmostApp: ""), .commandBracket,
                     "an unknown app gets the method that works nearly everywhere")
    }
}
