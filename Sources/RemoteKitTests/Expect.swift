import Foundation

/// Minimal assertion harness.
///
/// Command Line Tools ships neither swift-testing nor XCTest, and pulling
/// swift-testing in conflicts with Defaults over swift-syntax, so the checks
/// run as an ordinary executable instead.
enum Expect {
    nonisolated(unsafe) private static var failures: [String] = []
    nonisolated(unsafe) private static var checks = 0
    nonisolated(unsafe) private static var suite = ""

    static func suite(_ name: String, _ body: () -> Void) {
        suite = name
        print("\n\(name)")
        body()
    }

    static func that(
        _ condition: Bool,
        _ description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checks += 1
        if condition {
            print("  ✓ \(description)")
        } else {
            print("  ✗ \(description)  (\(file):\(line))")
            failures.append("\(suite): \(description)")
        }
    }

    static func equal<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checks += 1
        if actual == expected {
            print("  ✓ \(description)")
        } else {
            print("  ✗ \(description)\n      expected: \(expected)\n      actual:   \(actual)")
            failures.append("\(suite): \(description)")
        }
    }

    /// Returns the process exit code.
    static func summarise() -> Int32 {
        print("\n\(checks - failures.count)/\(checks) checks passed")
        guard failures.isEmpty else {
            print("\nFailures:")
            failures.forEach { print("  • \($0)") }
            return 1
        }
        return 0
    }
}
