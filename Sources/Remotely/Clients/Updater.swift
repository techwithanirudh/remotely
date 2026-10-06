import Defaults
import Foundation
import RemotelyKit
@preconcurrency import Sparkle

/// Sparkle owns the automatic settings, so these read through to it rather than
/// mirroring into `Defaults`, which left its dialog and this app disagreeing.
@MainActor
final class Updater: NSObject {
    static let shared = Updater()

    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    private var hasStarted = false
    private var watchers: [UUID: (String?) -> Void] = [:]

    /// The version the last check found, nil when up to date or never checked.
    /// Every finished check reports, even an unchanged answer, so Settings can
    /// refresh its last-checked date off the same signal.
    private(set) var availableVersion: String? {
        didSet {
            for watcher in watchers.values {
                watcher(availableVersion)
            }
        }
    }

    var canCheck: Bool { controller.updater.canCheckForUpdates }
    var lastCheck: Date? { controller.updater.lastUpdateCheckDate }

    var checksAutomatically: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    var installsAutomatically: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }

    var channel: ReleaseChannel {
        get { Defaults[.releaseChannel] }
        set {
            Defaults[.releaseChannel] = newValue
            guard hasStarted else { return }
            controller.updater.checkForUpdatesInBackground()
        }
    }

    override init() {
        super.init()
        start()
    }

    func checkForUpdates() {
        start()
        controller.updater.checkForUpdates()
    }

    /// Asks the feed without showing any of Sparkle's windows.
    func probe() {
        start()
        controller.updater.checkForUpdateInformation()
    }

    func watchAvailability() -> AsyncStream<String?> {
        let id = UUID()
        return AsyncStream { continuation in
            continuation.yield(availableVersion)
            watchers[id] = { continuation.yield($0) }
            continuation.onTermination = { _ in
                Task { @MainActor in Updater.shared.watchers[id] = nil }
            }
        }
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true
        controller.startUpdater()
    }
}

extension Updater: SPUUpdaterDelegate {
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        MainActor.assumeIsolated { channel.allowedChannels }
    }

    nonisolated func updater(_: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        MainActor.assumeIsolated { availableVersion = version }
    }

    nonisolated func updaterDidNotFindUpdate(_: SPUUpdater) {
        MainActor.assumeIsolated { availableVersion = nil }
    }
}
