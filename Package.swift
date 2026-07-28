// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteBridge",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RemoteCore", targets: ["RemoteCore"]),
        .executable(name: "RemoteBridge", targets: ["RemoteBridge"]),
    ],
    targets: [
        .target(name: "RemoteCore"),
        .executableTarget(
            name: "RemoteBridge",
            dependencies: ["RemoteCore"]
        ),
    ]
)
