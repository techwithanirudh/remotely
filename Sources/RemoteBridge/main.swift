import AppKit
import RemoteCore

if CommandLine.arguments.contains("--dry-run") {
    let parser = CECLineParser()
    while let line = readLine() {
        if let command = parser.parse(line) {
            print(command.rawValue)
        }
    }
} else if CommandLine.arguments.contains("--diagnose-cec") {
    let client = CECClient()
    client.onStateChange = { print("state:", $0) }
    client.onLog = { print($0) }
    client.onCommand = { print("button:", $0.rawValue) }
    let seconds = CommandLine.arguments
        .drop(while: { $0 != "--diagnose-cec" })
        .dropFirst()
        .first
        .flatMap(Double.init) ?? 20
    client.start()
    print("listening \(Int(seconds))s — press remote buttons now")
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    client.stop()
} else {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    application.run()
}
