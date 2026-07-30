import RemotelyKit

func statusTests() {
    Expect.suite("Status") {
        Expect.equal(RemoteStatus(link: .listening, hasAccessibility: false), .needsPermission,
                     "a live link without permission is not ready")
        Expect.equal(RemoteStatus(link: .listening, hasAccessibility: true), .ready,
                     "a live link with permission is ready")
        Expect.equal(
            RemoteStatus(link: .waitingForDisplay, hasAccessibility: false),
            .needsPermission,
            "permission is reported before the missing display"
        )
        Expect.equal(
            RemoteStatus(link: .waitingForDisplay, hasAccessibility: true),
            .waitingForRemote,
            "with permission granted the wait is on the display"
        )
        Expect.equal(RemoteStatus(link: .stopped, hasAccessibility: true), .paused,
                     "being switched off reads as paused")
    }
}
