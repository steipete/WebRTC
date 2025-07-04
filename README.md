# WebRTC XCFramework for macOS ARM64 with H265

Prebuilt WebRTC XCFramework for Apple Silicon Macs with H265/HEVC and AV1 codec support. Distributed as a Swift Package with binary target for easy integration.

> **Version Note**: This release (M139) is built from WebRTC's main branch, providing the latest features and codec improvements. For production use, consider building from a stable milestone branch. See [VERSIONING.md](VERSIONING.md) for details.

## Features

- **🎯 H265/HEVC & AV1**: Next-gen video codecs with hardware acceleration
- **🚀 Apple Silicon Native**: Optimized for ARM64 (M1/M2/M3)
- **📦 XCFramework**: Universal framework format
- **🔧 Swift Package Manager**: Binary distribution ready
- **⚙️ XCConfig Included**: Drop-in configuration files

## Quick Integration

### Swift Package Manager (Recommended)

```swift
dependencies: [
    .package(url: "https://github.com/steipete/WebRTC", from: "M139")
]
```

### Xcode Integration

1. File → Add Package Dependencies
2. Enter: `https://github.com/steipete/WebRTC`
3. Select version: "M139"
4. Click "Add Package"

### Manual Framework Integration

1. Download `WebRTC.xcframework.zip` from [Releases](https://github.com/steipete/WebRTC/releases)
2. Unzip and drag `WebRTC.xcframework` into your Xcode project
3. In target settings, ensure "Embed & Sign" is selected
4. Add required system frameworks in Build Phases → Link Binary:
   - AVFoundation.framework
   - CoreMedia.framework
   - CoreVideo.framework
   - VideoToolbox.framework
   - AudioToolbox.framework
   - CoreAudio.framework
   - Network.framework

## Usage Guide

### Basic Setup

```swift
import WebRTC

class WebRTCManager {
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    
    init() {
        // Initialize SSL (required once per app lifecycle)
        RTCInitializeSSL()
        
        // Create peer connection factory
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }
    
    deinit {
        // Cleanup SSL
        RTCCleanupSSL()
    }
}
```

### Creating a Peer Connection

```swift
func createPeerConnection() -> RTCPeerConnection? {
    let config = RTCConfiguration()
    
    // Configure STUN/TURN servers
    config.iceServers = [
        RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
        RTCIceServer(
            urlStrings: ["turn:your-turn-server.com:3478"],
            username: "username",
            credential: "password"
        )
    ]
    
    // Additional configuration
    config.bundlePolicy = .maxBundle
    config.rtcpMuxPolicy = .require
    config.tcpCandidatePolicy = .disabled
    config.candidateNetworkPolicy = .all
    config.continualGatheringPolicy = .gatherContinually
    
    // Create constraints
    let constraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
    )
    
    // Create peer connection
    return peerConnectionFactory.peerConnection(
        with: config,
        constraints: constraints,
        delegate: self
    )
}
```

### Camera Capture with H265

```swift
class CameraCapture {
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?
    private var localVideoTrack: RTCVideoTrack?
    
    func setupCamera(factory: RTCPeerConnectionFactory) {
        // Create video source and track
        videoSource = factory.videoSource()
        localVideoTrack = factory.videoTrack(with: videoSource!, trackId: "video0")
        
        // Create camera capturer
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource!)
        
        // Start capture
        startCapture()
    }
    
    func startCapture() {
        guard let capturer = videoCapturer,
              let camera = RTCCameraVideoCapturer.captureDevices().first else { return }
        
        // Find best format (prefer 1080p)
        let formats = RTCCameraVideoCapturer.supportedFormats(for: camera)
        let targetWidth = 1920
        let targetHeight = 1080
        
        var selectedFormat: AVCaptureDevice.Format?
        var currentDiff = Int.max
        
        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(targetWidth - Int(dimension.width)) + abs(targetHeight - Int(dimension.height))
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
            }
        }
        
        guard let format = selectedFormat else { return }
        
        // Get suitable fps
        let fps = self.getMaxSupportedFramerate(for: format)
        
        // Start capture
        capturer.startCapture(with: camera, format: format, fps: fps)
    }
    
    private func getMaxSupportedFramerate(for format: AVCaptureDevice.Format) -> Int {
        var maxFramerate = 0.0
        for range in format.videoSupportedFrameRateRanges {
            maxFramerate = max(maxFramerate, range.maxFrameRate)
        }
        return min(Int(maxFramerate), 30) // Cap at 30fps for performance
    }
}
```

### Screen Sharing

```swift
class ScreenShare {
    private var screenSource: RTCVideoSource?
    private var screenTrack: RTCVideoTrack?
    private var screenCapturer: RTCVideoCapturer?
    
    func setupScreenShare(factory: RTCPeerConnectionFactory) {
        // Create screen source
        screenSource = factory.videoSource()
        screenTrack = factory.videoTrack(with: screenSource!, trackId: "screen0")
        
        // Create custom screen capturer
        screenCapturer = RTCVideoCapturer(delegate: screenSource!)
        
        // Start screen capture
        startScreenCapture()
    }
    
    func startScreenCapture() {
        // Request screen recording permission
        CGRequestScreenCaptureAccess()
        
        // Capture main display
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureScreen()
        }
    }
    
    private func captureScreen() {
        let displayID = CGMainDisplayID()
        let displayBounds = CGDisplayBounds(displayID)
        
        // Create display stream
        var displayStreamConfig = CGDisplayStreamConfiguration()
        
        let displayStream = CGDisplayStreamCreate(
            displayID,
            Int(displayBounds.width),
            Int(displayBounds.height),
            Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
            nil,
            CGDisplayStreamFrameAvailableHandler { status, displayTime, frameSurface, updateRef in
                // Convert IOSurface to CVPixelBuffer and send to WebRTC
                // Implementation depends on your specific needs
            }
        )
        
        if let stream = displayStream {
            CGDisplayStreamStart(stream)
        }
    }
}
```

### Configuring H265/HEVC Codec

```swift
func preferH265Codec(factory: RTCPeerConnectionFactory) -> RTCRtpTransceiverInit {
    let transceiverInit = RTCRtpTransceiverInit()
    transceiverInit.direction = .sendRecv
    
    // Get available codecs
    let videoCodecs = RTCDefaultVideoEncoderFactory.supportedCodecs()
    
    // Find H265 codec
    let h265Codec = videoCodecs.first { $0.name == kRTCVideoCodecH265Name }
    
    // Set codec preferences with H265 first
    if let h265 = h265Codec {
        transceiverInit.sendEncodings = [
            RTCRtpEncodingParameters(rid: "h").apply {
                $0.isActive = true
                $0.maxBitrateBps = NSNumber(value: 2_000_000) // 2 Mbps for high quality
                $0.maxFramerate = NSNumber(value: 30)
                $0.scaleResolutionDownBy = NSNumber(value: 1.0)
            }
        ]
    }
    
    return transceiverInit
}

// Extension helper
extension NSObject {
    func apply(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}
```

### Audio Configuration

```swift
func setupAudio(factory: RTCPeerConnectionFactory) -> RTCMediaStreamTrack? {
    // Configure audio session
    let audioSession = RTCAudioSession.sharedInstance()
    audioSession.lockForConfiguration()
    do {
        try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
        try audioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        try audioSession.setActive(true)
    } catch {
        print("Failed to configure audio session: \(error)")
    }
    audioSession.unlockForConfiguration()
    
    // Create audio source and track
    let audioSource = factory.audioSource(with: nil)
    let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
    
    return audioTrack
}
```

### Handling Peer Connection Events

```swift
extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Stream added with \(stream.videoTracks.count) video tracks")
        
        if let videoTrack = stream.videoTracks.first {
            // Attach to video renderer (e.g., RTCMTLVideoView)
            DispatchQueue.main.async {
                self.remoteVideoTrack = videoTrack
                videoTrack.add(self.remoteVideoView)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected:
            print("ICE connected")
        case .disconnected:
            print("ICE disconnected")
        case .failed:
            print("ICE failed")
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Send candidate to remote peer via signaling
        let candidateData = [
            "candidate": candidate.sdp,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? ""
        ] as [String : Any]
        
        // Send via your signaling channel
    }
}
```

### Video Rendering with Metal

```swift
import MetalKit

class VideoViewController: NSViewController {
    @IBOutlet weak var localVideoView: RTCMTLVideoView!
    @IBOutlet weak var remoteVideoView: RTCMTLVideoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure video views
        localVideoView.videoContentMode = .scaleAspectFill
        remoteVideoView.videoContentMode = .scaleAspectFill
        
        // Enable video tracks
        if let localTrack = webRTCManager.localVideoTrack {
            localTrack.add(localVideoView)
        }
    }
}
```

### Creating and Handling Offers/Answers

```swift
func createOffer() {
    let constraints = RTCMediaConstraints(
        mandatoryConstraints: [
            "OfferToReceiveVideo": "true",
            "OfferToReceiveAudio": "true"
        ],
        optionalConstraints: nil
    )
    
    peerConnection?.offer(for: constraints) { [weak self] sdp, error in
        guard let self = self, let sdp = sdp else {
            print("Failed to create offer: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        // Set local description
        self.peerConnection?.setLocalDescription(sdp) { error in
            if let error = error {
                print("Failed to set local description: \(error.localizedDescription)")
                return
            }
            
            // Send offer to remote peer via signaling
            self.sendOffer(sdp)
        }
    }
}

func handleAnswer(_ answerSDP: String) {
    let sessionDescription = RTCSessionDescription(type: .answer, sdp: answerSDP)
    
    peerConnection?.setRemoteDescription(sessionDescription) { error in
        if let error = error {
            print("Failed to set remote description: \(error.localizedDescription)")
        }
    }
}
```

### Data Channel

```swift
func createDataChannel() -> RTCDataChannel? {
    let config = RTCDataChannelConfiguration()
    config.isOrdered = true
    config.isNegotiated = false
    
    let dataChannel = peerConnection?.dataChannel(forLabel: "data", configuration: config)
    dataChannel?.delegate = self
    
    return dataChannel
}

// RTCDataChannelDelegate
extension WebRTCManager: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary {
            let data = buffer.data
            // Handle binary data
        } else {
            let text = String(data: buffer.data, encoding: .utf8)
            // Handle text message
        }
    }
}
```

### Stats Collection

```swift
func collectStats() {
    peerConnection?.statistics { stats in
        for stat in stats {
            if stat.type == "outbound-rtp" && stat.values["mediaType"] as? String == "video" {
                let bitrate = stat.values["bytesSent"] as? Int ?? 0
                let packets = stat.values["packetsSent"] as? Int ?? 0
                print("Video bitrate: \(bitrate / 1000) kbps, packets: \(packets)")
            }
        }
    }
}
```

## Building from Source

### Prerequisites

- macOS 14.0+ (Sonoma)
- Apple Silicon Mac
- Xcode 15+
- 60GB free disk space
- Python 3
- Homebrew with Opus: `brew install opus`

### One-Command Build

```bash
./build_all.sh
```

This runs all steps automatically:
1. Sets up Google depot_tools
2. Fetches WebRTC source (~20GB)
3. Builds with H265 and AV1 enabled
4. Creates XCFramework
5. Prepares for distribution

### Configuration

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

## Framework Details

- **Binary Size**: ~250MB optimized (70MB compressed) - see [Size Optimizations](#size-optimizations)
- **Architecture**: arm64 only
- **Min Deployment**: macOS 14.0
- **Language**: Objective-C/C++ (Swift compatible)
- **Dependencies**: System Opus library (via Homebrew)

### Included Codecs

**Video**
- H.264 (hardware accelerated)
- H.265/HEVC (hardware accelerated) ✨
- VP8
- VP9
- AV1 ✨

**Audio**
- Opus (using system library for smaller size)
- G.711 (PCMU/PCMA)
- G.722 (disabled by default)
- iLBC (disabled by default)
- iSAC (disabled by default)

## Release Process

### Manual Release

```bash
# 1. Build everything
./build_all.sh

# 2. Prepare release
./scripts/prepare_release.sh

# 3. Create GitHub release
./scripts/create_release.sh

# The release will be tagged with the current Chromium milestone (e.g., M139)
```

## Troubleshooting

### Build Issues

**Missing depot_tools**
```bash
export PATH="$PWD/depot_tools:$PATH"
```

**Out of space**
```bash
# Clean build artifacts
rm -rf src/out
```

### Integration Issues

**Framework not found**
- Ensure "Embed & Sign" is selected
- Check Framework Search Paths

**Missing symbols**
- Link required system frameworks (see Manual Framework Integration)

**Code signing**
- Use "Embed & Sign" for local development
- May need to re-sign for distribution

## Size Optimizations

This build includes aggressive size optimizations that reduce the binary from ~416MB to ~250MB:

### Compiler Optimizations
- **Link-Time Optimization (LTO)**: Cross-module optimization and dead code elimination
- **Size-optimized compilation**: `-Os` flag prioritizes size over speed
- **Section-based linking**: Functions and data in separate sections for better stripping
- **Symbol stripping**: All debug symbols removed

### Feature Reductions
- **Audio codecs**: Only Opus (system) and G.711 enabled by default
- **Legacy APIs**: Removed deprecated video quality observer and legacy modules
- **Debug features**: Disabled metrics, trace events, and transient suppressor
- **Platform code**: Removed X11, PipeWire, GTK support

### System Libraries
- **Opus**: Uses macOS system library (requires `brew install opus`)
- **SSL**: Uses native macOS Security framework

### Further Size Reduction Options

For minimal builds, you can disable additional codecs:

```bash
# Disable large video codecs (saves ~130MB+)
export ENABLE_AV1=false    # Saves ~80-100MB
export ENABLE_VP9=false    # Saves ~30-40MB
export ENABLE_METRICS=false # Saves ~5MB

./build_all.sh
```

This produces a ~150MB binary suitable for H.264/H.265-only applications.

See [SIZE_OPTIMIZATIONS.md](SIZE_OPTIMIZATIONS.md) for detailed optimization information.

## Performance Tips

### H.265 Optimization
- Use hardware encoding when available
- Set appropriate bitrate limits (1-4 Mbps for 1080p)
- Monitor CPU usage with Activity Monitor

### Memory Management
- Release unused peer connections
- Remove video renderers when not visible
- Call RTCCleanupSSL() on app termination

### Size vs Performance Trade-offs
- The `-Os` optimization may slightly reduce performance (typically <5%)
- LTO increases build time but improves runtime performance
- System Opus requires runtime linking but reduces memory usage

## License

- Build Scripts: MIT License
- WebRTC: [BSD 3-Clause](https://webrtc.googlesource.com/src/+/main/LICENSE)

## Support

- Issues: [GitHub Issues](https://github.com/steipete/WebRTC/issues)
- WebRTC Docs: [webrtc.org](https://webrtc.org)

---

Built with ❤️ for the Apple development community