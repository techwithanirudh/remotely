import Defaults
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
}
