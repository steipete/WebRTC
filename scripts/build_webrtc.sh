#!/bin/bash

# Build WebRTC framework for macOS ARM with H265 support
# This script compiles WebRTC with specific configurations for Apple Silicon

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPOT_TOOLS_DIR="$PROJECT_ROOT/depot_tools"
SRC_DIR="$PROJECT_ROOT/src"
WEBRTC_SRC="$SRC_DIR/src"
BUILD_DIR="$PROJECT_ROOT/build"

# Load build configuration
if [ -f "$PROJECT_ROOT/build_config.sh" ]; then
    source "$PROJECT_ROOT/build_config.sh"
fi

# Show configuration if verbose
if [ "$VERBOSE_BUILD" = "true" ]; then
    print_config
fi

# Ensure depot_tools is in PATH
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# Check prerequisites
if [ ! -d "$WEBRTC_SRC" ]; then
    echo "Error: WebRTC source not found. Please run fetch_webrtc.sh first"
    exit 1
fi

cd "$WEBRTC_SRC"

# Function to generate GN args for a specific configuration
generate_gn_args() {
    local target_os=$1
    local target_cpu=$2
    local out_dir=$3
    
    local args="target_os=\"$target_os\""
    args="$args target_cpu=\"$target_cpu\""
    args="$args is_debug=false"
    args="$args is_component_build=false"
    args="$args rtc_include_tests=false"
    args="$args rtc_enable_protobuf=false"
    args="$args rtc_include_pulse_audio=false"
    args="$args rtc_build_examples=false"
    args="$args rtc_build_tools=false"
    args="$args rtc_use_gtk=false"
    args="$args treat_warnings_as_errors=false"
    args="$args use_custom_libcxx=false"
    args="$args use_rtti=true"
    
    # Codec support
    if [ "$ENABLE_H265" = "true" ]; then
        args="$args rtc_use_h265=true"
        args="$args ffmpeg_branding=\"Chrome\""
        args="$args proprietary_codecs=true"
    fi
    
    # VP9 codec
    if [ "$ENABLE_VP9" = "true" ]; then
        args="$args rtc_libvpx_build_vp9=true"
    else
        args="$args rtc_libvpx_build_vp9=false"
    fi
    
    # AV1 codec
    if [ "$ENABLE_AV1" = "true" ]; then
        args="$args rtc_use_libaom_av1_decoder=true"
        args="$args rtc_use_libaom_av1_encoder=true"
    fi
    
    # Audio codecs
    args="$args rtc_include_opus=$ENABLE_OPUS"
    args="$args rtc_include_ilbc=$ENABLE_ILBC"
    args="$args rtc_include_isac=$ENABLE_ISAC"
    
    # Features
    args="$args rtc_enable_sctp=$ENABLE_SCTP"
    args="$args rtc_enable_external_auth=$ENABLE_EXTERNAL_AUTH"
    
    # Optimizations
    if [ "$STRIP_SYMBOLS" = "true" ]; then
        args="$args strip_debug_info=true"
    fi
    
    # macOS specific settings
    if [ "$target_os" = "mac" ]; then
        args="$args mac_deployment_target=\"14.0\""
        args="$args enable_dsyms=$ENABLE_DSYMS"
    fi
    
    # iOS specific settings
    if [ "$target_os" = "ios" ]; then
        args="$args ios_deployment_target=\"12.0\""
        args="$args enable_ios_bitcode=$BITCODE"
        args="$args ios_enable_code_signing=false"
        args="$args use_xcode_clang=true"
    fi
    
    echo "$args"
}

# Function to build WebRTC for a specific configuration
build_webrtc() {
    local platform=$1
    local arch=$2
    local out_name=$3
    
    echo "Building WebRTC for $platform ($arch)..."
    
    local out_dir="out/$out_name"
    
    # Generate GN args
    local gn_args=$(generate_gn_args "$platform" "$arch" "$out_dir")
    
    # Create output directory and write args
    gn gen "$out_dir" --args="$gn_args"
    
    # Build - use default target which builds everything needed
    ninja -C "$out_dir"
    
    echo "Build complete for $platform ($arch)"
}

# Create build directory
mkdir -p "$BUILD_DIR"

# Build configurations
echo "Starting WebRTC builds..."

# macOS ARM64
build_webrtc "mac" "arm64" "mac_arm64"

# Optional: Build for Intel Mac
# build_webrtc "mac" "x64" "mac_x64"

# Optional: Build for iOS
# build_webrtc "ios" "arm64" "ios_arm64"
# build_webrtc "ios" "arm64" "ios_sim_arm64"

echo "All builds completed!"

# Save build info
cat > "$BUILD_DIR/build_info.json" <<EOF
{
  "webrtc_commit": "$(git rev-parse HEAD)",
  "webrtc_branch": "$(git branch -r --contains HEAD | grep -E 'branch-heads/[0-9]+' | head -1 | sed 's/.*branch-heads\///')",
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "build_type": "$BUILD_TYPE",
  "h265_enabled": $ENABLE_H265,
  "platforms": ["mac_arm64"]
}
EOF