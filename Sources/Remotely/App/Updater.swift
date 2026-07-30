import Combine
import Defaults
import RemotelyKit
@preconcurrency import Sparkle

/// Sparkle, wrapped so nothing else has to know about it.
///
/// Sparkle owns the automatic settings, so these read through to it rather than
/// mirroring into `Defaults`, which left its own dialog and this app disagreeing.
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
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheck)
        controller.updater.publisher(for: \.lastUpdateCheckDate).assign(to: &$lastCheck)

        // Sparkle's dialog writes to its defaults without notifying anyone.
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
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        MainActor.assumeIsolated { channel.allowedChannels }
    }
}
