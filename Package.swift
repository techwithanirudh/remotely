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
                .product(name: "Defaults", package: "Defaults"),
            ]
        ),
        // Command Line Tools ships neither swift-testing nor XCTest, and
        // pulling swift-testing in conflicts with Defaults over swift-syntax.
        // A plain executable keeps the checks runnable: `swift run RemoteKitTests`.
        .executableTarget(name: "RemoteKitTests", dependencies: ["RemoteKit"]),
    ]
)
