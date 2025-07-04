#!/bin/bash

# Package WebRTC into Framework and XCFramework
# This script creates distributable framework packages from compiled WebRTC

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"
WEBRTC_SRC="$SRC_DIR/src"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Check if build exists
if [ ! -d "$WEBRTC_SRC/out/mac_arm64" ]; then
    echo "Error: WebRTC build not found. Please run build_webrtc.sh first"
    exit 1
fi

cd "$WEBRTC_SRC"

# Create output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Function to create framework structure
create_framework() {
    local platform=$1
    local arch=$2
    local build_dir=$3
    local framework_name="WebRTC"
    local framework_dir="$OUTPUT_DIR/${framework_name}.framework"
    
    echo "Creating framework for $platform ($arch)..."
    
    # Create framework structure
    mkdir -p "$framework_dir/Headers"
    mkdir -p "$framework_dir/Modules"
    
    # Combine all static libraries into one
    local libs=(
        "$build_dir/obj/sdk/libbase_objc.a"
        "$build_dir/obj/sdk/libvideocapture_objc.a"
        "$build_dir/obj/sdk/libvideoframebuffer_objc.a"
        "$build_dir/obj/sdk/libframe_objc.a"
        "$build_dir/obj/sdk/librtc_sdk_objc.a"
        "$build_dir/obj/rtc_base/librtc_base.a"
        "$build_dir/obj/api/librtc_api.a"
        "$build_dir/obj/modules/libwebrtc.a"
        "$build_dir/obj/pc/librtc_pc.a"
        "$build_dir/obj/sdk/librtc_sdk_peerconnection_objc.a"
    )
    
    # Find and include all necessary static libraries
    find "$build_dir/obj" -name "*.a" -type f > "$OUTPUT_DIR/all_libs.txt"
    
    # Use the main WebRTC library that was built
    echo "Creating framework library..."
    
    # Check for the main WebRTC library
    webrtc_lib="$build_dir/obj/libwebrtc.a"
    
    if [ ! -f "$webrtc_lib" ]; then
        echo "Error: WebRTC library not found at $webrtc_lib"
        exit 1
    fi
    
    echo "Using WebRTC library: $(ls -lh "$webrtc_lib" | awk '{print $5}')"
    
    # Copy the library to the framework
    cp "$webrtc_lib" "$framework_dir/$framework_name"
    
    if [ ! -f "$framework_dir/$framework_name" ]; then
        echo "Error: Failed to copy library to framework"
        exit 1
    fi
    
    # Copy headers
    echo "Copying headers..."
    
    # WebRTC public headers
    local header_dirs=(
        "sdk/objc/base"
        "sdk/objc/components/capturer"
        "sdk/objc/components/renderer/opengl"
        "sdk/objc/components/renderer/metal"
        "sdk/objc/components/video_codec"
        "sdk/objc/api/peerconnection"
        "sdk/objc/api/logging"
        "sdk/objc/api/video_codec"
        "sdk/objc/api/video_frame_buffer"
    )
    
    for header_dir in "${header_dirs[@]}"; do
        if [ -d "$header_dir" ]; then
            find "$header_dir" -name "*.h" -type f | while read -r header; do
                # Preserve directory structure
                relative_path="${header#sdk/objc/}"
                header_dest_dir="$framework_dir/Headers/$(dirname "$relative_path")"
                mkdir -p "$header_dest_dir"
                cp "$header" "$header_dest_dir/"
            done
        fi
    done
    
    # Create umbrella header
    cat > "$framework_dir/Headers/$framework_name.h" <<EOF
//
//  WebRTC.h
//  WebRTC
//
//  Generated framework umbrella header
//

#import <Foundation/Foundation.h>

// Base
#import <WebRTC/RTCMacros.h>
#import <WebRTC/RTCLogging.h>
#import <WebRTC/RTCFieldTrials.h>
#import <WebRTC/RTCSSLAdapter.h>
#import <WebRTC/RTCTracing.h>
#import <WebRTC/RTCCertificate.h>
#import <WebRTC/RTCCryptoOptions.h>
#import <WebRTC/RTCEncodedImage.h>

// PeerConnection
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCDataChannel.h>
#import <WebRTC/RTCDataChannelConfiguration.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCMediaSource.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCMediaStreamTrack.h>
#import <WebRTC/RTCMetrics.h>
#import <WebRTC/RTCMetricsSampleInfo.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCPeerConnectionFactoryOptions.h>
#import <WebRTC/RTCRtcpParameters.h>
#import <WebRTC/RTCRtpCodecParameters.h>
#import <WebRTC/RTCRtpEncodingParameters.h>
#import <WebRTC/RTCRtpHeaderExtension.h>
#import <WebRTC/RTCRtpParameters.h>
#import <WebRTC/RTCRtpReceiver.h>
#import <WebRTC/RTCRtpSender.h>
#import <WebRTC/RTCRtpTransceiver.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCStatisticsReport.h>
#import <WebRTC/RTCLegacyStatsReport.h>

// Video
#import <WebRTC/RTCVideoSource.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCVideoRenderer.h>
#import <WebRTC/RTCVideoFrame.h>
#import <WebRTC/RTCVideoFrameBuffer.h>
#import <WebRTC/RTCI420Buffer.h>
#import <WebRTC/RTCMutableI420Buffer.h>
#import <WebRTC/RTCMutableYUVPlanarBuffer.h>
#import <WebRTC/RTCYUVPlanarBuffer.h>

// Audio
#import <WebRTC/RTCAudioSource.h>
#import <WebRTC/RTCAudioTrack.h>
#import <WebRTC/RTCAudioSession.h>
#import <WebRTC/RTCAudioSessionConfiguration.h>

// Codecs
#import <WebRTC/RTCVideoCodecConstants.h>
#import <WebRTC/RTCVideoCodecInfo.h>
#import <WebRTC/RTCVideoDecoder.h>
#import <WebRTC/RTCVideoDecoderFactory.h>
#import <WebRTC/RTCVideoEncoder.h>
#import <WebRTC/RTCVideoEncoderFactory.h>
#import <WebRTC/RTCVideoEncoderSettings.h>
#import <WebRTC/RTCVideoEncoderQpThresholds.h>
EOF

    # Create module map
    cat > "$framework_dir/Modules/module.modulemap" <<EOF
framework module $framework_name {
    umbrella header "$framework_name.h"
    
    export *
    module * { export * }
}
EOF

    # Create Info.plist
    cat > "$framework_dir/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$framework_name</string>
    <key>CFBundleIdentifier</key>
    <string>org.webrtc.$framework_name</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$framework_name</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>$(git rev-parse --short HEAD)</string>
    <key>MinimumOSVersion</key>
    <string>11.0</string>
</dict>
</plist>
EOF
    
    echo "Framework created: $framework_dir"
}

# Build framework for macOS ARM64
create_framework "mac" "arm64" "$WEBRTC_SRC/out/mac_arm64"

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$OUTPUT_DIR/WebRTC.framework" \
    -output "$OUTPUT_DIR/WebRTC.xcframework"

echo "XCFramework created: $OUTPUT_DIR/WebRTC.xcframework"

# Create distribution archive
echo "Creating distribution archive..."
cd "$OUTPUT_DIR"
zip -r "WebRTC-macOS-arm64-h265.zip" "WebRTC.xcframework"

echo "Package complete!"
echo "Output: $OUTPUT_DIR/WebRTC-macOS-arm64-h265.zip"