import Combine
import Defaults
import RemotelyKit
@preconcurrency import Sparkle

/// Sparkle, wrapped so nothing else has to know about it.
///
/// The updater is created but not started. Starting it validates the feed URL
/// and the public key, and a failure there is what produces Sparkle's "the
/// updater failed to start" alert, so it is deferred to the first check rather
/// than run at launch.
///
/// Automatic downloading stays off. The build is ad-hoc signed, so an update
/// writes a bundle with a different signature and macOS revokes Accessibility,
/// which would leave the remote silently dead. Until releases are notarized an
/// update only happens when the user asks for one.
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
    }

    func checkForUpdates() {
        start()
        controller.updater.checkForUpdates()
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true
        controller.updater.automaticallyDownloadsUpdates = false
        controller.startUpdater()
    }
}

extension Updater: SPUUpdaterDelegate {
    /// Beta releases are opt-in. An empty set means stable only, which is what
    /// an appcast entry with no channel is.
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        MainActor.assumeIsolated { wantsBeta ? ["beta"] : [] }
    }
}
