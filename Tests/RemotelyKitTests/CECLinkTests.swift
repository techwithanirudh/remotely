import RemotelyKit

@MainActor
func cecLinkTests() {
    Expect.suite("CEC listener lifecycle") {
        let link = CECLink()
        var states: [CECLink.State] = []
        link.onStateChange = { states.append($0) }

        link.start()
        Expect.equal(states.first, .idle, "startup begins waiting for a button")

        link.stop()
        Expect.equal(states, [.idle, .stopped], "an explicit stop is reported once")
    }
}
