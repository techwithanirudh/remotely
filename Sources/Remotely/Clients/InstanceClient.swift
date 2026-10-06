import AppKit
import ComposableArchitecture

/// Two copies would both read the CEC log and post every press twice. The
/// newest launch wins, so installing a build replaces the one already running.
@DependencyClient
struct InstanceClient: Sendable {
    /// Asks every other running copy to quit and waits until they have.
    var claim: @Sendable () async -> Void
    /// Yields when a newer copy asks this one to quit.
    var superseded: @Sendable () async -> AsyncStream<Void> = { .finished }
}

extension InstanceClient: DependencyKey {
    static let liveValue = Self(
        claim: {
            let others = await MainActor.run { InstanceClientLive.broadcast() }
            await InstanceClientLive.waitForExit(others)
        },
        superseded: { await MainActor.run { InstanceClientLive.observe() } }
    )

    static let testValue = Self()
    static let previewValue = Self(claim: {}, superseded: { .finished })
}

extension DependencyValues {
    var instanceClient: InstanceClient {
        get { self[InstanceClient.self] }
        set { self[InstanceClient.self] = newValue }
    }
}

private enum InstanceClientLive {
    static let quit = Notification.Name("com.anirudh.remotely.quit")
    static let ownPID = ProcessInfo.processInfo.processIdentifier

    @MainActor
    static func broadcast() -> [pid_t] {
        // A bare `swift run` binary has no bundle to compare against.
        guard let bundleID = Bundle.main.bundleIdentifier else { return [] }
        let others = NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == bundleID && $0.processIdentifier != ownPID }
            .map(\.processIdentifier)
        guard !others.isEmpty else { return [] }

        // The sender rides in `object`, which arrives even where userInfo is stripped.
        DistributedNotificationCenter.default().postNotificationName(
            quit,
            object: String(ownPID),
            userInfo: nil,
            deliverImmediately: true
        )
        return others
    }

    static func waitForExit(_ pids: [pid_t]) async {
        guard !pids.isEmpty else { return }
        let deadline = ContinuousClock.now + .seconds(3)

        while ContinuousClock.now < deadline {
            if pids.allSatisfy({ !isRunning($0) }) { return }
            try? await Task.sleep(for: .milliseconds(100))
        }

        for pid in pids where isRunning(pid) {
            kill(pid, SIGKILL)
        }
    }

    @MainActor
    static func observe() -> AsyncStream<Void> {
        AsyncStream { continuation in
            nonisolated(unsafe) let token = DistributedNotificationCenter.default().addObserver(
                forName: quit,
                object: nil,
                queue: .main
            ) { notification in
                guard notification.object as? String != String(ownPID) else { return }
                continuation.yield()
            }
            continuation.onTermination = { _ in
                DistributedNotificationCenter.default().removeObserver(token)
            }
        }
    }

    private static func isRunning(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }
}
