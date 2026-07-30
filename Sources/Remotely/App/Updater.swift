import Combine
import Defaults
import RemotelyKit
@preconcurrency import Sparkle

/// Sparkle, wrapped so nothing else has to know about it.
///
/// Sparkle owns the two automatic settings, not this app. Mirroring them into
/// `Defaults` gave two sources of truth: ticking "Automatically download and
/// install updates in the future" in Sparkle's own dialog left the Settings
/// toggle showing off. These read and write through to Sparkle, and Sparkle
/// persists them under `SUEnableAutomaticChecks` and `SUAutomaticallyUpdate`.
@MainActor
final class Updater: NSObject, ObservableObject {
    static let shared = Updater()

    @Published private(set) var canCheck = false
    @Published private(set) var lastCheck: Date?

    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    private var hasStarted = false
    private var observers = Set<AnyCancellable>()

    var checksAutomatically: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    var installsAutomatically: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }

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

        // Sparkle's dialog writes straight to its defaults without telling us,
        // so the settings screen has to hear about it from there.
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &observers)

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
    /// Beta releases are opt-in. An empty set means stable only, which is what
    /// an appcast entry with no channel is.
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        MainActor.assumeIsolated { wantsBeta ? ["beta"] : [] }
    }
}
