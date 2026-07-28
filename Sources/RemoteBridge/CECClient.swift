import Foundation
import RemoteCore

/// Receives HDMI-CEC remote buttons on any Mac with a CEC-capable HDMI port.
///
/// macOS owns the CEC bus in the `corercd` system daemon. Its private CoreRC
/// XPC service refuses bus enumeration to third-party clients — `queryBusesAsync:`
/// answers `NSOSStatusErrorDomain -6773` — and without a bus object the daemon
/// routes no HID events to us, so the framework path yields nothing.
///
/// The same daemon does emit every decoded button to the unified log, readable
/// without any entitlement, so that is the transport used here.
final class CECClient: NSObject, @unchecked Sendable {
    enum State: Equatable {
        case stopped
        case unsupported
        case waitingForHDMI
        case running
        case failed(String)
    }

    var onStateChange: ((State) -> Void)?
    var onCommand: ((RemoteCommand) -> Void)?
    var onRelease: (() -> Void)?
    var onLog: ((String) -> Void)?
    var onDisplayChange: ((String) -> Void)?

    private var process: Process?
    private var buffer = Data()
    private var lastState: State?
    private var lastDisplayName: String?
    private let parser = CECLogParser()

    @MainActor
    func start() {
        stop()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "stream",
            "--predicate", "process == \"corercd\"",
            "--debug",
            "--style", "compact",
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            self?.consume(chunk)
        }

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.setState(.stopped) }
        }

        do {
            try process.run()
        } catch {
            setState(.failed(error.localizedDescription))
            return
        }

        self.process = process
        setState(.waitingForHDMI)
    }

    @MainActor
    func stop() {
        if let process {
            (process.standardOutput as? Pipe)?.fileHandleForReading.readabilityHandler = nil
            process.terminationHandler = nil
            if process.isRunning { process.terminate() }
        }
        process = nil
        buffer.removeAll()
        lastDisplayName = nil
        setState(.stopped)
    }

    private func consume(_ chunk: Data) {
        buffer.append(chunk)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer[buffer.startIndex..<newline]
            buffer.removeSubrange(buffer.startIndex...newline)
            guard let line = String(data: lineData, encoding: .utf8) else { continue }
            handle(line: line)
        }
    }

    private func handle(line: String) {
        guard let event = parser.parse(line) else { return }
        Task { @MainActor in
            switch event {
            case let .attached(display):
                self.setState(.running)
                guard self.lastDisplayName != display else { return }
                self.lastDisplayName = display
                self.onDisplayChange?(display)
                self.onLog?("CEC link up: \(display)")
            case let .pressed(command):
                self.setState(.running)
                self.onCommand?(command)
            case .released:
                self.onRelease?()
            }
        }
    }

    @MainActor
    private func setState(_ state: State) {
        guard state != lastState else { return }
        lastState = state
        onStateChange?(state)
    }
}
