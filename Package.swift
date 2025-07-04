// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [
        .macOS(.v14),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/steipete/WebRTC/releases/download/v1.0.0/WebRTC.xcframework.zip",
            checksum: "a2a2717c71438b1306a439664accea2c9268e8b8d551e169a288db096ce6c7b5"
        )
    ]
)