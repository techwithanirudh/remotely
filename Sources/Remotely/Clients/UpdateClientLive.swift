import RemotelyKit

@MainActor
final class UpdateClientLive {
    static let shared = UpdateClientLive()

    private let updater = Updater.shared

    func snapshot() -> UpdateClient.Snapshot {
        UpdateClient.Snapshot(
            canCheck: updater.canCheck,
            lastCheck: updater.lastCheck,
            checksAutomatically: updater.checksAutomatically,
            installsAutomatically: updater.installsAutomatically,
            channel: updater.channel
        )
    }

    func checkForUpdates() { updater.checkForUpdates() }
    func setChecksAutomatically(_ value: Bool) { updater.checksAutomatically = value }
    func setInstallsAutomatically(_ value: Bool) { updater.installsAutomatically = value }
    func setChannel(_ channel: ReleaseChannel) { updater.channel = channel }
}
