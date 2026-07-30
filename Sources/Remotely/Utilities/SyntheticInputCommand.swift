import AppKit
import Foundation
import RemotelyKit

enum SyntheticInputCommand {
    private enum ExitCode {
        static let usage: Int32 = 64
        static let unavailable: Int32 = 69
        static let software: Int32 = 70
        static let noPermission: Int32 = 77
    }

    @MainActor
    static func runIfRequested(arguments: [String]) -> Bool {
        guard let index = arguments.firstIndex(of: "--synthesize") else { return false }
        guard arguments.indices.contains(index + 1),
              let action = RemoteAction(rawValue: arguments[index + 1])
        else {
            fail("usage: Remote --synthesize <action> [--target <bundle-id>]"
                + " [--method <navigation-method>]",
                code: ExitCode.usage)
        }
        let method = navigationMethod(in: arguments)
        if method != nil, action != .browserBack, action != .browserForward {
            fail("--method only applies to browserBack and browserForward",
                 code: ExitCode.usage)
        }
        let target = targetBundleIdentifier(in: arguments)
        let targetApp = target.map { bundleIdentifier in
            guard let app = NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .first
            else {
                fail("Target is not running: \(bundleIdentifier)", code: ExitCode.unavailable)
            }
            return app
        }
        guard InputSynthesizer.hasAccessibility else {
            fail("Remotely does not have Accessibility permission",
                 code: ExitCode.noPermission)
        }

        if let target, let targetApp {
            activate(targetApp, bundleIdentifier: target)
            centerPointer(in: targetApp.processIdentifier)
        }

        let input = InputSynthesizer()
        input.perform(
            ButtonBinding(action),
            targetApp: target,
            navigationMethod: method
        )
        let pointer = CGEvent(source: nil)?.location ?? .zero
        write("Pointer \(Int(pointer.x)),\(Int(pointer.y))")
        if !input.lastNavigation.isEmpty { write(input.lastNavigation) }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        return true
    }

    private static func targetBundleIdentifier(in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "--target") else { return nil }
        guard arguments.indices.contains(index + 1),
              !arguments[index + 1].hasPrefix("--")
        else {
            fail("usage: Remote --synthesize <action> --target <bundle-id>",
                 code: ExitCode.usage)
        }
        return arguments[index + 1]
    }

    private static func navigationMethod(in arguments: [String]) -> NavigationMethod? {
        guard let index = arguments.firstIndex(of: "--method") else { return nil }
        guard arguments.indices.contains(index + 1) else {
            fail("--method requires a value", code: ExitCode.usage)
        }
        switch arguments[index + 1] {
        case "swipe": return .swipe
        case "mouse-button": return .mouseButton
        case "command-bracket": return .commandBracket
        case "option-command-bracket": return .optionCommandBracket
        case "command-arrow": return .commandArrow
        default:
            fail("Unknown navigation method: \(arguments[index + 1])",
                 code: ExitCode.usage)
        }
    }

    @MainActor
    private static func activate(
        _ app: NSRunningApplication,
        bundleIdentifier: String
    ) {
        guard app.activate() else {
            fail("Could not activate target: \(bundleIdentifier)", code: ExitCode.software)
        }

        let deadline = Date(timeIntervalSinceNow: 0.5)
        while NSWorkspace.shared.frontmostApplication?.processIdentifier != app.processIdentifier,
              Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
        }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
        else {
            fail("Target did not become active: \(bundleIdentifier)", code: ExitCode.software)
        }
    }

    private static func fail(_ message: String, code: Int32) -> Never {
        fputs("\(message)\n", stderr)
        exit(code)
    }

    private static func write(_ message: String) {
        FileHandle.standardOutput.write(Data("\(message)\n".utf8))
    }

    private static func centerPointer(in processID: pid_t) {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
            as? [[CFString: Any]]
        else { return }

        let rect = windows.compactMap { window -> CGRect? in
            guard (window[kCGWindowOwnerPID] as? pid_t) == processID,
                  (window[kCGWindowLayer] as? Int) == 0,
                  let bounds = window[kCGWindowBounds] as? [CFString: Any]
            else { return nil }
            return CGRect(dictionaryRepresentation: bounds as CFDictionary)
        }
        .max { $0.width * $0.height < $1.width * $1.height }

        if let rect {
            CGWarpMouseCursorPosition(CGPoint(x: rect.midX, y: rect.midY))
        }
    }
}
