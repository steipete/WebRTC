#!/bin/bash

# WebRTC Build Configuration
# This file contains all configurable options for building WebRTC

# Build Type Configuration
export BUILD_TYPE="${BUILD_TYPE:-Release}"              # Release or Debug
export ENABLE_DSYMS="${ENABLE_DSYMS:-false}"           # Generate dSYM files for debugging

# Codec Configuration
export ENABLE_H265="${ENABLE_H265:-true}"              # Enable H265/HEVC codec
export ENABLE_VP9="${ENABLE_VP9:-true}"                # Enable VP9 codec
export ENABLE_AV1="${ENABLE_AV1:-false}"               # Enable AV1 codec (disabled for size)

# Audio Configuration
export ENABLE_OPUS="${ENABLE_OPUS:-true}"              # Enable Opus audio codec
export ENABLE_G711="${ENABLE_G711:-false}"             # Enable G.711 audio codec (disabled - Opus is enough)
export ENABLE_G722="${ENABLE_G722:-false}"             # Enable G.722 audio codec
export ENABLE_ILBC="${ENABLE_ILBC:-false}"             # Enable iLBC audio codec
export ENABLE_ISAC="${ENABLE_ISAC:-false}"             # Enable iSAC audio codec

# Platform Configuration
export BUILD_MAC="${BUILD_MAC:-true}"                  # Build for macOS
export BUILD_IOS="${BUILD_IOS:-false}"                 # Build for iOS
export BUILD_IOS_SIM="${BUILD_IOS_SIM:-false}"        # Build for iOS Simulator
export BUILD_CATALYST="${BUILD_CATALYST:-false}"       # Build for Mac Catalyst

# Optimization Configuration
export ENABLE_BITCODE="${ENABLE_BITCODE:-false}"       # Enable bitcode (iOS only)
export STRIP_SYMBOLS="${STRIP_SYMBOLS:-true}"          # Strip debug symbols
export ENABLE_ASSERTIONS="${ENABLE_ASSERTIONS:-false}" # Enable runtime assertions
export ENABLE_LTO="${ENABLE_LTO:-true}"                # Enable Link-Time Optimization
export ENABLE_THIN_LTO="${ENABLE_THIN_LTO:-true}"      # Use Thin LTO (faster than full LTO)
export OPTIMIZE_FOR_SIZE="${OPTIMIZE_FOR_SIZE:-true}"  # Optimize for binary size
export SYMBOL_LEVEL="${SYMBOL_LEVEL:-0}"               # Symbol level (0=none, 1=minimal, 2=full)

# Feature Configuration
export ENABLE_SIMULCAST="${ENABLE_SIMULCAST:-true}"    # Enable simulcast support
export ENABLE_PROTOBUF="${ENABLE_PROTOBUF:-false}"     # Enable protobuf (increases size)
export ENABLE_SCTP="${ENABLE_SCTP:-true}"             # Enable SCTP for data channels
export ENABLE_EXTERNAL_AUTH="${ENABLE_EXTERNAL_AUTH:-true}" # Enable external auth
export ENABLE_METRICS="${ENABLE_METRICS:-true}"        # Enable metrics collection
export ENABLE_TESTS="${ENABLE_TESTS:-false}"           # Build test binaries
export ENABLE_EXAMPLES="${ENABLE_EXAMPLES:-false}"     # Build example programs
export ENABLE_TOOLS="${ENABLE_TOOLS:-false}"           # Build WebRTC tools
export USE_SYSTEM_SSL="${USE_SYSTEM_SSL:-false}"        # Use BoringSSL to match WebRTC defaults
export USE_SYSTEM_OPUS="${USE_SYSTEM_OPUS:-false}"      # Use bundled Opus for consistency

# Build System Configuration
export BUILD_STATIC="${BUILD_STATIC:-true}"            # Build as static library
export PARALLEL_JOBS="${PARALLEL_JOBS:-}"              # Number of parallel build jobs (empty = auto)
export CCACHE_ENABLED="${CCACHE_ENABLED:-false}"       # Use ccache for faster rebuilds

# Output Configuration
export OUTPUT_DIR="${OUTPUT_DIR:-output}"              # Output directory for built frameworks
export ARCHIVE_BUILDS="${ARCHIVE_BUILDS:-true}"        # Create zip archives of builds

# Logging Configuration
export VERBOSE_BUILD="${VERBOSE_BUILD:-false}"         # Enable verbose build output
export LOG_FILE="${LOG_FILE:-build.log}"              # Build log file

# Print configuration summary
print_config() {
    echo "=== WebRTC Build Configuration ==="
    echo "Build Type: $BUILD_TYPE"
    echo "Enable dSYMs: $ENABLE_DSYMS"
    echo ""
    echo "Codecs:"
    echo "  H265/HEVC: $ENABLE_H265"
    echo "  VP9: $ENABLE_VP9"
    echo "  AV1: $ENABLE_AV1"
    echo "  Opus: $ENABLE_OPUS"
    echo ""
    echo "Platforms:"
    echo "  macOS: $BUILD_MAC"
    echo "  iOS: $BUILD_IOS"
    echo "  iOS Simulator: $BUILD_IOS_SIM"
    echo "  Mac Catalyst: $BUILD_CATALYST"
    echo ""
    echo "Features:"
    echo "  Simulcast: $ENABLE_SIMULCAST"
    echo "  Data Channels: $ENABLE_SCTP"
    echo "  External Auth: $ENABLE_EXTERNAL_AUTH"
    echo "  Metrics: $ENABLE_METRICS"
    echo "================================="
}