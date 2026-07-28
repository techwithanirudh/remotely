import AppKit
import RemoteCore

if CommandLine.arguments.contains("--diagnose-cec") {
    let seconds = CommandLine.arguments
        .drop(while: { $0 != "--diagnose-cec" })
        .dropFirst()
        .first
        .flatMap(Double.init) ?? 20

    let client = CECClient()
    client.onStateChange = { print("state:", $0) }
    client.onLog = { print($0) }
    client.onCommand = { print("press:", $0.rawValue) }
    client.onRelease = { print("release") }

    client.start()
    print("listening \(Int(seconds))s, press remote buttons now")
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    client.stop()
} else {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.regular)
    application.run()
}
