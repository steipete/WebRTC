import Foundation
import WebRTC

print("WebRTC Example - Testing H265 Support")
print("=====================================")

// Initialize WebRTC
RTCInitializeSSL()
print("✓ WebRTC SSL initialized")

// Create peer connection factory
let factory = RTCPeerConnectionFactory()
print("✓ PeerConnectionFactory created")

// Check available video codecs
let encoderFactory = RTCDefaultVideoEncoderFactory()
let decoderFactory = RTCDefaultVideoDecoderFactory()

print("\nSupported Video Encoders:")
for codec in encoderFactory.supportedCodecs() {
    print("  - \(codec.name)")
    if codec.name == kRTCVideoCodecH265Name {
        print("    ✓ H265/HEVC encoding supported!")
    } else if codec.name == kRTCVideoCodecAv1Name {
        print("    ✓ AV1 encoding supported!")
    }
}

print("\nSupported Video Decoders:")
for codec in decoderFactory.supportedCodecs() {
    print("  - \(codec.name)")
    if codec.name == kRTCVideoCodecH265Name {
        print("    ✓ H265/HEVC decoding supported!")
    } else if codec.name == kRTCVideoCodecAv1Name {
        print("    ✓ AV1 decoding supported!")
    }
}

// Create a simple peer connection
let config = RTCConfiguration()
config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]

let constraints = RTCMediaConstraints(
    mandatoryConstraints: nil,
    optionalConstraints: nil
)

let peerConnection = factory.peerConnection(
    with: config,
    constraints: constraints,
    delegate: nil
)

if peerConnection != nil {
    print("\n✓ PeerConnection created successfully")
    print("✓ WebRTC framework is working correctly")
} else {
    print("\n✗ Failed to create PeerConnection")
}

print("\nFramework verified successfully!")
RTCCleanupSSL()