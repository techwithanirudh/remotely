import RemoteKit

@MainActor
func cecLinkTests() {
    Expect.suite("CEC listener lifecycle") {
        let link = CECLink()
        var states: [CECLink.State] = []
        link.onStateChange = { states.append($0) }

        link.start()
        Expect.equal(states.first, .waitingForDisplay, "startup begins with the actual wait state")

        link.stop()
        Expect.equal(states, [.waitingForDisplay, .stopped], "an explicit stop is reported once")
    }
}
