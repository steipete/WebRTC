# WebRTC XCFramework for macOS ARM64 with H265

Prebuilt WebRTC XCFramework for Apple Silicon Macs with H265/HEVC codec support. Distributed as a Swift Package with binary target for easy integration.

## Features

- **🎯 H265/HEVC & AV1**: Next-gen video codecs with hardware acceleration
- **🚀 Apple Silicon Native**: Optimized for ARM64 (M1/M2/M3)
- **📦 XCFramework**: Universal framework format
- **🔧 Swift Package Manager**: Binary distribution ready
- **⚙️ XCConfig Included**: Drop-in configuration files
- **🤖 Automated Builds**: GitHub Actions CI/CD

## Quick Integration

### Swift Package Manager (Recommended)

```swift
dependencies: [
    .package(url: "https://github.com/steipete/WebRTC", from: "1.0.0")
]
```

### Xcode Integration

1. File → Add Package Dependencies
2. Enter: `https://github.com/steipete/WebRTC`
3. Click "Add Package"

### XCConfig Integration

```xcconfig
#include "Pods/WebRTC/xcconfig/WebRTC.xcconfig"
```

## Building from Source

### Prerequisites

- macOS 14.0+ (Sonoma)
- Apple Silicon Mac
- Xcode 15+
- 60GB free disk space
- Python 3

### One-Command Build

```bash
./build_all.sh
```

This runs all steps automatically:
1. Sets up Google depot_tools
2. Fetches WebRTC source (~20GB)
3. Builds with H265 enabled
4. Creates XCFramework
5. Prepares for distribution

### Manual Build Steps

```bash
# 1. Setup build tools
./scripts/setup_depot_tools.sh

# 2. Fetch WebRTC source
./scripts/fetch_webrtc.sh

# 3. Build WebRTC
./scripts/build_webrtc.sh

# 4. Package framework
./scripts/package_framework.sh

# 5. Prepare release
./scripts/prepare_release.sh
```

## Configuration

Edit `build_config.sh` to customize:

```bash
# Codecs
ENABLE_H265=true    # H.265/HEVC
ENABLE_VP9=true     # VP9
ENABLE_AV1=true     # AV1

# Audio
ENABLE_OPUS=true    # Opus
ENABLE_G711=true    # G.711

# Build Options
BUILD_TYPE=Release  # Release/Debug
STRIP_SYMBOLS=true  # Smaller binary
```

## Usage Example

```swift
import WebRTC

// Initialize
RTCInitializeSSL()

// Create factory
let factory = RTCPeerConnectionFactory()

// Configure connection
let config = RTCConfiguration()
config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]

// Create peer connection
let peerConnection = factory.peerConnection(with: config, 
                                           constraints: RTCMediaConstraints(),
                                           delegate: self)

// Video with H265
let videoSource = factory.videoSource()
let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")

// Configure H265 codec
let h265Codec = RTCVideoCodecInfo(name: kRTCVideoCodecH265Name)
let encoderFactory = RTCDefaultVideoEncoderFactory()
factory.setVideoEncoderFactory(encoderFactory)
```

## Output Structure

```
output/
├── WebRTC.xcframework/          # Universal framework
│   ├── Info.plist
│   └── macos-arm64/
│       └── WebRTC.framework/
│           ├── WebRTC           # 416MB binary
│           ├── Headers/         # Public headers
│           └── Modules/         # Module map
└── WebRTC-macOS-arm64-h265.zip # Compressed (115MB)
```

## XCConfig Files

Included configuration files for easy project integration:

- `xcconfig/WebRTC.xcconfig` - Base configuration
- `xcconfig/WebRTC-Debug.xcconfig` - Debug settings
- `xcconfig/WebRTC-Release.xcconfig` - Release settings

### Using XCConfig

1. Copy `xcconfig` folder to your project
2. In Xcode project settings:
   - Debug: Select `WebRTC-Debug.xcconfig`
   - Release: Select `WebRTC-Release.xcconfig`

## Framework Details

- **Binary Size**: ~416MB (115MB compressed)
- **Architecture**: arm64 only
- **Min Deployment**: macOS 14.0
- **Language**: Objective-C/C++ (Swift compatible)
- **Dependencies**: None (self-contained)

### Included Codecs

**Video**
- H.264 (hardware accelerated)
- H.265/HEVC (hardware accelerated) ✨
- VP8
- VP9
- AV1 ✨

**Audio**
- Opus
- G.711 (PCMU/PCMA)
- G.722
- iLBC
- iSAC

## Troubleshooting

### Build Issues

**Missing depot_tools**
```bash
export PATH="$PWD/depot_tools:$PATH"
```

**Out of space**
```bash
# Clean build artifacts
rm -rf src/src/out
```

**Xcode version**
```bash
sudo xcode-select -s /Applications/Xcode.app
```

### Integration Issues

**Framework not found**
- Ensure "Embed & Sign" is selected
- Check Framework Search Paths

**Missing symbols**
- Link required system frameworks:
  - AVFoundation
  - CoreMedia
  - VideoToolbox
  - AudioToolbox

**Code signing**
- Use "Embed & Sign" for local development
- May need to re-sign for distribution

## CI/CD

GitHub Actions automatically:
- Builds weekly (Mondays)
- Creates releases
- Calculates checksums
- Updates Package.swift

### Manual Release

```bash
# 1. Build everything
./build_all.sh

# 2. Prepare release
./scripts/prepare_release.sh

# 3. Tag and push
git tag v1.0.0
git push --tags

# 4. Upload WebRTC.xcframework.zip to GitHub release
```

## Performance

### H.265 Benefits
- 40-50% bandwidth reduction vs H.264
- Better quality at same bitrate
- Hardware encoding/decoding on Apple Silicon
- Lower CPU usage

### Build Performance
- Full build: 1-3 hours
- Incremental: 10-30 minutes
- Peak RAM: ~6GB
- CPU: Uses all cores

## Security

- Official WebRTC source only
- No modifications to security code
- Regular updates via CI/CD
- Code signed frameworks

## License

- Build Scripts: MIT License
- WebRTC: [BSD 3-Clause](https://webrtc.googlesource.com/src/+/main/LICENSE)

## Support

- Issues: [GitHub Issues](https://github.com/steipete/WebRTC/issues)
- WebRTC Docs: [webrtc.org](https://webrtc.org)

---

Built with ❤️ for the Apple development community