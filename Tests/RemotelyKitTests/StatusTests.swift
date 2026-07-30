import RemotelyKit

func statusTests() {
    Expect.suite("Status") {
        Expect.equal(
            RemoteStatus(link: .listening, hasAccessibility: false, hasDisplay: true),
            .needsPermission,
            "a live link without permission is not ready"
        )
        Expect.equal(
            RemoteStatus(link: .listening, hasAccessibility: true, hasDisplay: true),
            .ready,
            "a live link with permission is ready"
        )
        Expect.equal(
            RemoteStatus(link: .waitingForDisplay, hasAccessibility: false, hasDisplay: true),
            .needsPermission,
            "permission is reported before anything about the display"
        )
        Expect.equal(
            RemoteStatus(link: .waitingForDisplay, hasAccessibility: true, hasDisplay: true),
            .waitingForRemote,
            "a display is attached, so only a button press is missing"
        )
        Expect.equal(
            RemoteStatus(link: .waitingForDisplay, hasAccessibility: true, hasDisplay: false),
            .noDisplay,
            "no display at all is a different problem from an unheard remote"
        )
        Expect.equal(
            RemoteStatus(link: .stopped, hasAccessibility: true, hasDisplay: true),
            .paused,
            "being switched off reads as paused"
        )
    }
}
