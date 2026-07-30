import RemotelyKit

func navigationTests() {
    Expect.suite("Back and Forward") {
        Expect.equal(NavigationMethod(targetApp: "com.microsoft.VSCode"), .mouseButton,
                     "VS Code takes mouse button 4 or 5")
        Expect.equal(NavigationMethod(targetApp: "at.studio.AsideBrowser"), .mouseButton,
                     "Aside gets the non-Apple mouse-button default")
        Expect.equal(NavigationMethod(targetApp: "com.apple.finder"), .commandBracket,
                     "Finder uses its Back menu shortcut")
        Expect.equal(NavigationMethod(targetApp: "com.apple.systempreferences"), .commandBracket,
                     "System Settings uses Command-bracket")
        Expect.equal(NavigationMethod(targetApp: "com.operasoftware.Opera"), .swipe,
                     "Opera takes only the swipe")
        Expect.equal(NavigationMethod(targetApp: "com.apple.Notes"), .optionCommandBracket,
                     "plain Command-bracket indents in Notes")
        Expect.equal(NavigationMethod(targetApp: "com.apple.iCal"), .commandArrow,
                     "Command-bracket moves between occurrences in Calendar")
        Expect.equal(NavigationMethod(targetApp: "dev.warp.Warp-Stable"), .commandBracket,
                     "Warp takes the bracket")
        Expect.equal(NavigationMethod(targetApp: ""), .mouseButton,
                     "an unknown app gets the broad non-Apple fallback")
    }
}
