import Combine
import Defaults
import RemotelyKit
@preconcurrency import Sparkle

/// Sparkle, wrapped so nothing else has to know about it.
///
/// Automatic downloading stays off. Accessibility is granted against the app's
/// code signature, and an ad-hoc signature changes on every build, so installing
/// an update silently revokes it and leaves the remote dead. A stable signing
/// identity fixes that; notarization is a separate concern.
@MainActor
final class Updater: NSObject, ObservableObject {
    @Published private(set) var canCheck = false
    @Published private(set) var lastCheck: Date?

    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    private var hasStarted = false

    var wantsBeta: Bool {
        get { Defaults[.wantsBetaUpdates] }
        set {
            Defaults[.wantsBetaUpdates] = newValue
            guard hasStarted else { return }
            controller.updater.checkForUpdatesInBackground()
        }
    }

    override init() {
        super.init()
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheck)
        controller.updater.publisher(for: \.lastUpdateCheckDate).assign(to: &$lastCheck)
        start()
    }

    func checkForUpdates() {
        start()
        controller.updater.checkForUpdates()
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true
        controller.updater.automaticallyDownloadsUpdates = false
        controller.updater.automaticallyChecksForUpdates = Defaults[.checksForUpdatesAutomatically]
        controller.startUpdater()

        Defaults.observe(.checksForUpdatesAutomatically) { [weak self] change in
            self?.controller.updater.automaticallyChecksForUpdates = change.newValue
        }.tieToLifetime(of: self)
    }
}

extension Updater: SPUUpdaterDelegate {
    /// Beta releases are opt-in. An empty set means stable only, which is what
    /// an appcast entry with no channel is.
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        MainActor.assumeIsolated { wantsBeta ? ["beta"] : [] }
    }
}
