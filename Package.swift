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
            url: "https://github.com/steipete/WebRTC/releases/download/M139-dynamic/WebRTC-macOS-arm64-h265-dynamic.zip",
            checksum: "c7f9bd55222116c3dd36772a367bef839545fbc1503c57d9d1fff67d697b090d"
        )
    ]
)