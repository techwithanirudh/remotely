// swift-tools-version: 6.0
import PackageDescription

/// Verified against these sources: each is free today, no errors and no
/// warnings. InternalImportsByDefault is deliberately absent — it produced 100+
/// errors in RemotelyKit and needs every import auditing first.
let strict: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
]

let package = Package(
    name: "Remotely",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RemotelyKit", targets: ["RemotelyKit"]),
        .executable(name: "Remotely", targets: ["Remotely"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            revision: "7517cc32aa083773f096dc4724a0b83215bf3c55"
        ),
        // Type-safe UserDefaults.
        .package(url: "https://github.com/sindresorhus/Defaults", from: "9.0.0"),
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "2.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.4"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "RemotelyKit",
            dependencies: [.product(name: "Defaults", package: "Defaults")],
            swiftSettings: strict
        ),
        .executableTarget(
            name: "Remotely",
            dependencies: [
                "RemotelyKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "ConfettiSwiftUI",
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            swiftSettings: strict,
            // Sparkle links as @rpath/Sparkle.framework, and the bundle is
            // assembled by hand, so the binary needs to be told where the
            // Frameworks folder is relative to itself.
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
        // Command Line Tools ships neither swift-testing nor XCTest, and
        // pulling swift-testing in conflicts with Defaults over swift-syntax.
        // A plain executable keeps the checks runnable: `swift run RemotelyKitTests`.
        .executableTarget(
            name: "RemotelyKitTests",
            dependencies: ["RemotelyKit"],
            path: "Tests/RemotelyKitTests"
        ),
    ]
)
