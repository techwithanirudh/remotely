import Foundation

/// Receives HDMI-CEC remote presses by parsing the unified log.
///
/// Not a mistake to be fixed: `corercd` owns the bus and its private XPC service
/// refuses enumeration to third parties (`queryBusesAsync:` answers
/// `NSOSStatusErrorDomain -6773`), so the framework route yields nothing.
@MainActor
public final class CECLink {
    public enum State: Equatable, Sendable, CustomStringConvertible {
        case stopped
        case unsupported
        case waitingForDisplay
        case listening
        case failed(String)

        public var description: String {
            switch self {
            case .stopped: "Stopped"
            case .unsupported: "Not supported on this Mac"
            case .waitingForDisplay: "Waiting for a display"
            case .listening: "Listening"
            case .failed(let reason): "Failed, \(reason)"
            }
        }
    }

    public var onStateChange: ((State) -> Void)?
    public var onPress: ((RemoteKey) -> Void)?
    public var onRelease: (() -> Void)?
    public var onDisplayName: ((String) -> Void)?
    public var onLog: ((String) -> Void)?

    private let parser = CECLogParser()
    private var stream: Process?
    private var buffer = Data()
    private var state: State?
    private var displayName: String?

    public init() {}

    public func start() {
        tearDown()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "stream",
            "--predicate", #"process == "corercd""#,
            "--debug",
            "--style", "compact",
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            Task { @MainActor in self?.consume(chunk) }
        }

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.transition(to: .stopped) }
        }

        do {
            try process.run()
        } catch {
            transition(to: .failed(error.localizedDescription))
            return
        }

        stream = process
        transition(to: .waitingForDisplay)
    }

    public func stop() {
        tearDown()
        transition(to: .stopped)
    }
}

private extension CECLink {
    func tearDown() {
        if let stream {
            (stream.standardOutput as? Pipe)?.fileHandleForReading.readabilityHandler = nil
            stream.terminationHandler = nil
            if stream.isRunning { stream.terminate() }
        }
        stream = nil
        buffer.removeAll()
        displayName = nil
    }

    func consume(_ chunk: Data) {
        buffer.append(chunk)

        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex ..< newline]
            buffer.removeSubrange(buffer.startIndex ... newline)

            if let text = String(data: line, encoding: .utf8) {
                handle(text)
            }
        }
    }

    func handle(_ line: String) {
        guard let event = parser.parse(line) else { return }

        switch event {
        case .attached(let display):
            transition(to: .listening)
            guard displayName != display else { return }
            displayName = display
            onDisplayName?(display)
            onLog?("Connected to \(display)")

        case .pressed(let key):
            transition(to: .listening)
            onPress?(key)

        case .released:
            onRelease?()
        }
    }

    func transition(to next: State) {
        guard next != state else { return }
        state = next
        onStateChange?(next)
    }
}
