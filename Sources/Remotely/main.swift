import AppKit
import RemotelyKit

// `--diagnose` prints CEC traffic without needing Accessibility, which is the
// quickest way to tell a dead link from a missing permission.
if SyntheticInputCommand.runIfRequested(arguments: CommandLine.arguments) {
    // The command owns the process and has already emitted its result.
} else if CommandLine.arguments.contains("--diagnose") {
    let link = CECLink()
    link.onStateChange = { print("link:", $0) }
    link.onPress = { print("press:", $0.title) }
    link.onRelease = { print("release") }
    link.onDisplayName = { print("display:", $0) }
    link.onLog = { print($0) }
    link.start()

    print("Listening for 8s, press remote buttons now")
    RunLoop.main.run(until: .now.addingTimeInterval(8))
    link.stop()
} else {
    let app = NSApplication.shared
    let coordinator = AppCoordinator()
    app.delegate = coordinator
    app.setActivationPolicy(.accessory)
    app.run()
}
