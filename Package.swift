// swift-tools-version: 6.0
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
            url: "https://github.com/steipete/WebRTC/releases/download/M139-dynamic/WebRTC.xcframework.zip",
            checksum: "4feb66305109584230e99d4bf2f8c91401001fc34872695e2c7a70dcf5b63c40"
        )
    ]
)