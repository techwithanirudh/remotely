// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "M7RemoteBridge",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "M7RemoteCore", targets: ["M7RemoteCore"]),
        .executable(name: "M7RemoteBridge", targets: ["M7RemoteBridge"]),
    ],
    targets: [
        .target(name: "M7RemoteCore"),
        .executableTarget(
            name: "M7RemoteBridge",
            dependencies: ["M7RemoteCore"]
        ),
    ]
)
