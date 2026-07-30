import Sparkle

/// Sparkle, wrapped so nothing else has to know about it.
///
/// Automatic installing is deliberately off. The build is ad-hoc signed, so an
/// update writes a bundle with a different signature and macOS revokes
/// Accessibility, which would leave the remote silently dead. Until releases are
/// notarized, an update only happens when the user asks for one.
@MainActor
final class Updater {
    private let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        controller.updater.automaticallyDownloadsUpdates = false
    }

    var canCheck: Bool { controller.updater.canCheckForUpdates }

    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
