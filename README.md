# WebRTC Framework for macOS ARM64 with H265

Prebuilt WebRTC framework for Apple Silicon Macs with H265 codec support, distributed as XCFramework for easy integration.

## Features

- **Apple Silicon Native**: Built specifically for ARM64 macOS
- **H265 Codec Support**: Enabled H265/HEVC video codec
- **XCFramework Format**: Universal framework for easy integration
- **Automated Builds**: Weekly builds tracking latest WebRTC releases
- **Swift Package Manager**: First-class SPM support

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/steipete/WebRTC", from: "5845.0.0")
]
```

### Direct Download

Download the latest release from the [Releases](https://github.com/steipete/WebRTC/releases) page.

## Building from Source

### Prerequisites

- macOS 14+ (Sonoma) on Apple Silicon
- Xcode 15+
- ~60GB free disk space
- ~8GB RAM minimum

### Quick Build

```bash
# Clone the repository
git clone https://github.com/steipete/WebRTC.git
cd WebRTC

# Setup build tools
./scripts/setup_depot_tools.sh

# Fetch WebRTC source
./scripts/fetch_webrtc.sh

# Build WebRTC with H265
./scripts/build_webrtc.sh

# Package as framework
./scripts/package_framework.sh
```

### Build Options

Configure build by setting environment variables:

```bash
# Enable/disable H265 codec (default: true)
export ENABLE_H265=true

# Build type (default: Release)
export BUILD_TYPE=Release

# Enable dSYMs (default: false)
export ENABLE_DSYMS=true
```

## Usage Example

```swift
import WebRTC

// Create peer connection factory
let factory = RTCPeerConnectionFactory()

// Create peer connection
let config = RTCConfiguration()
config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
let peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)

// Create video source and track
let videoSource = factory.videoSource()
let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")

// Add track to peer connection
peerConnection.add(videoTrack, streamIds: ["stream0"])
```

## Architecture

### Build Scripts

- `setup_depot_tools.sh`: Installs Google's depot_tools required for WebRTC
- `fetch_webrtc.sh`: Downloads WebRTC source code using gclient
- `build_webrtc.sh`: Compiles WebRTC with custom GN arguments for macOS ARM64
- `package_framework.sh`: Creates XCFramework from compiled libraries

### GN Build Configuration

Key build arguments for H265 support:

```gn
target_os = "mac"
target_cpu = "arm64"
rtc_use_h265 = true
proprietary_codecs = true
ffmpeg_branding = "Chrome"
```

## CI/CD

GitHub Actions workflow runs:
- Weekly builds tracking latest WebRTC
- Manual builds for specific branches
- Automatic release creation with artifacts

## License

WebRTC is licensed under the [BSD 3-Clause License](https://webrtc.googlesource.com/src/+/main/LICENSE).

This repository contains build scripts and is licensed under MIT License.

## Acknowledgments

- [stasel/WebRTC](https://github.com/stasel/WebRTC) for inspiration and build approach
- Google WebRTC team for the amazing library