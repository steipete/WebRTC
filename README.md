# WebRTC Build Infrastructure for macOS ARM64 with H265 Support

This project provides an automated build system for compiling Google's WebRTC library with H265/HEVC codec support specifically for macOS on Apple Silicon (ARM64). It packages the compiled library as an XCFramework for easy integration into macOS and iOS applications.

## 🎯 Key Features

- **H265/HEVC Support**: Enables hardware-accelerated H265 encoding and decoding
- **Apple Silicon Native**: Optimized for ARM64 architecture (M1/M2/M3 chips)
- **XCFramework Output**: Universal framework format for easy Xcode integration
- **Automated Build Process**: One-command build with configurable options
- **Swift Package Manager**: Ready for SPM integration
- **CI/CD Integration**: GitHub Actions for automated weekly builds

## 📋 System Requirements

- **macOS**: 14.0+ (Sonoma) or later
- **Hardware**: Apple Silicon Mac (M1/M2/M3)
- **Xcode**: 15.0 or later with command line tools
- **Storage**: ~60GB free disk space
- **RAM**: 8GB minimum, 16GB recommended
- **Network**: Stable internet connection (will download ~20GB)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/webrtc-build.git
cd webrtc-build
```

### 2. Run the Complete Build

```bash
./build_all.sh
```

This single command will:
1. Set up Google's depot_tools
2. Fetch WebRTC source code (~20GB download)
3. Build WebRTC with H265 support
4. Package as XCFramework
5. Create distributable zip file

The entire process takes 1-3 hours depending on your internet speed and Mac performance.

## 📖 Detailed Build Process

### Step 1: Setup Build Tools

```bash
./scripts/setup_depot_tools.sh
```

Downloads and configures Google's depot_tools, which provides:
- `gclient`: Manages WebRTC dependencies
- `gn`: Generates build files
- `ninja`: Executes the build

### Step 2: Fetch WebRTC Source

```bash
./scripts/fetch_webrtc.sh
```

Downloads WebRTC source code and all dependencies. This step:
- Creates `.gclient` configuration
- Syncs ~20GB of source code
- Captures current WebRTC version info

### Step 3: Build WebRTC

```bash
./scripts/build_webrtc.sh
```

Compiles WebRTC with your specified configuration:
- Enables H265/HEVC codecs
- Builds for macOS ARM64
- Creates static libraries
- Generates build metadata

### Step 4: Package Framework

```bash
./scripts/package_framework.sh
```

Creates the final framework:
- Combines static libraries
- Generates headers and module map
- Creates XCFramework structure
- Packages as distributable zip

## ⚙️ Build Configuration

Edit `scripts/build_config.sh` to customize your build:

### Codec Options

```bash
# Video Codecs
ENABLE_H265=true          # H265/HEVC support
ENABLE_VP9=true           # VP9 codec
ENABLE_AV1=false          # AV1 codec (experimental)

# Audio Codecs
ENABLE_OPUS=true          # Opus audio codec
ENABLE_G711=true          # G.711 (PCMU/PCMA)
ENABLE_G722=true          # G.722
ENABLE_ILBC=true          # iLBC
ENABLE_ISAC=true          # iSAC
```

### Build Options

```bash
# Build Type
BUILD_TYPE="Release"      # Or "Debug"

# Optimization
STRIP_SYMBOLS=true        # Reduce binary size
ENABLE_DSYM=false         # Generate dSYM for debugging

# Features
ENABLE_SIMULCAST=true     # Simulcast support
ENABLE_SCTP=true          # Data channels
```

### Platform Targets

```bash
# Primary target
TARGET_PLATFORM="mac"     # macOS native
TARGET_ARCH="arm64"       # Apple Silicon

# Additional platforms (for future expansion)
# TARGET_PLATFORM="ios"   # iOS devices
# TARGET_PLATFORM="iossimulator"  # iOS Simulator
# TARGET_PLATFORM="maccatalyst"   # Mac Catalyst
```

## 📦 Output Artifacts

After a successful build, you'll find:

### Build Directory (`build/`)
```
build/
├── webrtc/                    # WebRTC source code
├── frameworks/                # Built frameworks
│   └── WebRTC.xcframework/    # Universal framework
├── WebRTC-macOS-arm64-h265.zip  # Distributable package
└── build_info.json            # Build metadata
```

### Framework Structure
```
WebRTC.xcframework/
├── Info.plist                 # Framework metadata
└── macos-arm64/              # macOS ARM64 slice
    └── WebRTC.framework/
        ├── WebRTC            # Binary
        ├── Headers/          # Public headers
        ├── Modules/          # Module map
        └── Resources/        # Resources
```

## 🔧 Integration Guide

### Xcode Integration

1. Drag `WebRTC.xcframework` into your Xcode project
2. Ensure "Copy items if needed" is checked
3. Add to "Frameworks, Libraries, and Embedded Content"
4. Set to "Embed & Sign"

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/webrtc-build.git", from: "1.0.0")
]
```

### Basic Usage Example

```swift
import WebRTC

// Initialize WebRTC
RTCInitializeSSL()

// Create peer connection factory
let factory = RTCPeerConnectionFactory()

// Create video source with H265 support
let videoSource = factory.videoSource()
let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)

// Configure H265 codec
let h265Codec = RTCVideoCodecInfo(name: kRTCVideoCodecH265Name)
factory.setVideoDecoderFactory(RTCDefaultVideoDecoderFactory())
factory.setVideoEncoderFactory(RTCDefaultVideoEncoderFactory())
```

## 🐛 Troubleshooting

### Common Issues

**1. Build Fails with "Missing depot_tools"**
```bash
# Ensure depot_tools is in PATH
export PATH="$PWD/depot_tools:$PATH"
```

**2. Out of Disk Space**
- The build requires ~60GB total
- Clean previous builds: `rm -rf build/`
- Use `df -h` to check available space

**3. Xcode Version Errors**
```bash
# Select correct Xcode version
sudo xcode-select -s /Applications/Xcode.app
```

**4. Network Timeout During Fetch**
```bash
# Resume interrupted fetch
cd build/webrtc
gclient sync --force
```

### Build Logs

Check logs for detailed error information:
- Setup: `logs/setup_depot_tools.log`
- Fetch: `logs/fetch_webrtc.log`
- Build: `logs/build_webrtc.log`
- Package: `logs/package_framework.log`

## 🤖 CI/CD Integration

### GitHub Actions

The project includes automated builds via GitHub Actions:

**Weekly Builds**: Automatically builds latest WebRTC every Monday
```yaml
schedule:
  - cron: '0 0 * * 1'  # Every Monday at midnight
```

**Manual Builds**: Trigger builds with custom branches
```yaml
workflow_dispatch:
  inputs:
    webrtc_branch:
      description: 'WebRTC branch to build'
      default: 'main'
```

### Using Pre-built Releases

Instead of building yourself, you can download pre-built frameworks from the [Releases](https://github.com/your-org/webrtc-build/releases) page:

1. Download `WebRTC-macOS-arm64-h265.zip`
2. Unzip and find `WebRTC.xcframework`
3. Integrate into your project

## 📊 Performance Considerations

### H265 Benefits
- **Bandwidth**: 40-50% reduction compared to H264
- **Quality**: Better quality at same bitrate
- **Hardware**: Leverages Apple's hardware encoders

### Build Performance
- **Time**: 1-3 hours for complete build
- **CPU**: Uses all available cores
- **Memory**: Peak usage ~6GB
- **Cache**: Subsequent builds are faster

## 🔐 Security

- All builds use official WebRTC source
- No modifications to security-critical code
- Follows Chromium security practices
- Regular updates via CI/CD

## 📄 License

This build infrastructure is MIT licensed. WebRTC itself is licensed under the [BSD 3-Clause License](https://webrtc.org/support/license).

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-org/webrtc-build/issues)
- **Documentation**: [Wiki](https://github.com/your-org/webrtc-build/wiki)
- **WebRTC**: [Official WebRTC Documentation](https://webrtc.org)

## 🔄 Version Information

- **Build System**: 1.0.0
- **WebRTC**: Tracks latest stable branch
- **macOS Target**: 14.0+
- **Architecture**: ARM64 (Apple Silicon)

---

Built with ❤️ for the macOS development community