// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "WebRTCExample",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "WebRTCExample",
            dependencies: [
                .product(name: "WebRTC", package: "WebRTC")
            ]
        )
    ]
)