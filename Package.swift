// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteBridge",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RemoteKit", targets: ["RemoteKit"]),
        .executable(name: "RemoteBridge", targets: ["RemoteBridge"]),
    ],
    dependencies: [
        // Type-safe UserDefaults. Alcove links the same library.
        .package(url: "https://github.com/sindresorhus/Defaults", from: "9.0.0"),
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "2.0.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "RemoteKit",
            dependencies: [.product(name: "Defaults", package: "Defaults")]
        ),
        .executableTarget(
            name: "RemoteBridge",
            dependencies: [
                "RemoteKit",
                "ConfettiSwiftUI",
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
            ]
        ),
        // Command Line Tools ships neither swift-testing nor XCTest, and
        // pulling swift-testing in conflicts with Defaults over swift-syntax.
        // A plain executable keeps the checks runnable: `swift run RemoteKitTests`.
        .executableTarget(
            name: "RemoteKitTests",
            dependencies: ["RemoteKit"],
            path: "Tests/RemoteKitTests"
        ),
    ]
)
