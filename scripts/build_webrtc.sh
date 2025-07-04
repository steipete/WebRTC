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
    args="$args rtc_include_tests=$ENABLE_TESTS"
    args="$args rtc_enable_protobuf=$ENABLE_PROTOBUF"
    args="$args rtc_include_pulse_audio=false"
    args="$args rtc_build_examples=$ENABLE_EXAMPLES"
    args="$args rtc_build_tools=$ENABLE_TOOLS"
    args="$args rtc_use_gtk=false"
    args="$args treat_warnings_as_errors=false"
    args="$args use_custom_libcxx=false"
    args="$args use_rtti=true"
    
    # Link-Time Optimization
    if [ "$ENABLE_LTO" = "true" ]; then
        args="$args use_lto=true"
        if [ "$ENABLE_THIN_LTO" = "true" ]; then
            args="$args use_thin_lto=true"
        fi
    fi
    
    # Size optimizations
    if [ "$OPTIMIZE_FOR_SIZE" = "true" ]; then
        args="$args optimize_for_size=true"
    fi
    
    # Symbol stripping
    args="$args symbol_level=$SYMBOL_LEVEL"
    args="$args enable_stripping=true"
    args="$args remove_webcore_debug_symbols=true"
    
    # Dead code elimination
    args="$args enable_dead_code_stripping=true"
    
    # Disable legacy features
    args="$args rtc_enable_legacy_api_video_quality_observer=false"
    args="$args rtc_use_legacy_modules_directory=false"
    
    # Additional size optimizations
    args="$args rtc_disable_trace_events=true"
    args="$args rtc_exclude_transient_suppressor=true"
    args="$args rtc_disable_metrics=true"
    
    # Use system libraries where possible
    if [ "$USE_SYSTEM_SSL" = "true" ]; then
        args="$args rtc_build_ssl=false"
    fi
    
    if [ "$USE_SYSTEM_OPUS" = "true" ]; then
        args="$args rtc_build_opus=false"
        # Help WebRTC find system Opus on macOS
        args="$args rtc_opus_dir=\"/opt/homebrew/opt/opus\""
    fi
    
    # Compiler optimization flags for size
    local cflags=""
    local ldflags=""
    
    if [ "$USE_SYSTEM_OPUS" = "true" ]; then
        cflags="$cflags -I/opt/homebrew/opt/opus/include"
        ldflags="$ldflags -L/opt/homebrew/opt/opus/lib"
    fi
    
    if [ "$OPTIMIZE_FOR_SIZE" = "true" ]; then
        # Aggressive size optimization
        cflags="$cflags -Os -ffunction-sections -fdata-sections"
        ldflags="$ldflags -Wl,-dead_strip"  # macOS equivalent of --gc-sections
    fi
    
    if [ -n "$cflags" ]; then
        args="$args extra_cflags=\"$cflags\""
    fi
    
    if [ -n "$ldflags" ]; then
        args="$args extra_ldflags=\"$ldflags\""
    fi
    
    # Disable unnecessary platform features
    args="$args rtc_use_x11=false"
    args="$args rtc_use_pipewire=false"
    
    # Use optimized build tools
    args="$args use_clang_lld=true"
    args="$args clang_use_chrome_plugins=false"
    
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
    
    # G.711 and G.722 codec control
    if [ "$ENABLE_G711" = "false" ]; then
        args="$args rtc_include_builtin_audio_codecs=false"
    fi
    
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
  "version": "M139",
  "webrtc_commit": "$(git rev-parse HEAD)",
  "webrtc_branch": "$(git branch -r --contains HEAD | grep -E 'branch-heads/[0-9]+' | head -1 | sed 's/.*branch-heads\///')",
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "build_type": "$BUILD_TYPE",
  "h265_enabled": $ENABLE_H265,
  "platforms": ["mac_arm64"]
}
EOF