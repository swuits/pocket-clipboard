// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Pocket",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Pocket", targets: ["Pocket"])],
    targets: [
        .target(name: "PocketCore"),
        .executableTarget(name: "Pocket", dependencies: ["PocketCore"]),
        .testTarget(name: "PocketCoreTests", dependencies: ["PocketCore"]),
    ]
)
