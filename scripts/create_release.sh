#!/bin/bash

# Script to create a GitHub release for WebRTC framework
# Uses Chromium milestone versioning (e.g., M139)

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Install it with: brew install gh"
    exit 1
fi

# Get the current version from release_info.json
if [ -f "$PROJECT_ROOT/release/release_info.json" ]; then
    VERSION=$(grep '"version"' "$PROJECT_ROOT/release/release_info.json" | sed 's/.*: "\(.*\)".*/\1/')
else
    echo "Error: release/release_info.json not found"
    exit 1
fi

# Get build info
if [ -f "$PROJECT_ROOT/output/build_info.json" ]; then
    WEBRTC_COMMIT=$(grep '"webrtc_commit"' "$PROJECT_ROOT/output/build_info.json" | sed 's/.*: "\(.*\)".*/\1/')
    BUILD_DATE=$(grep '"build_date"' "$PROJECT_ROOT/output/build_info.json" | sed 's/.*: "\(.*\)".*/\1/')
fi

# Check if release file exists
RELEASE_FILE="$PROJECT_ROOT/release/WebRTC.xcframework.zip"
if [ ! -f "$RELEASE_FILE" ]; then
    echo "Error: Release file not found at $RELEASE_FILE"
    echo "Run ./scripts/package_framework.sh first"
    exit 1
fi

# Create release notes
RELEASE_NOTES="# WebRTC Framework $VERSION

Built from WebRTC commit: \`$WEBRTC_COMMIT\`
Build date: $BUILD_DATE

## Features
- 🎥 H.265/HEVC codec support
- 🎬 AV1 codec support  
- 📹 VP9 codec support
- 🎵 Opus audio codec
- 🍎 Apple Silicon (arm64) native
- 📦 XCFramework packaging
- 🚀 Swift Package Manager support

## Requirements
- macOS 14.0+
- Xcode 15.0+

## Installation

### Swift Package Manager
\`\`\`swift
dependencies: [
    .package(url: \"https://github.com/steipete/WebRTC.git\", from: \"$VERSION\")
]
\`\`\`

### Manual Integration
Download \`WebRTC.xcframework.zip\` from the assets below and follow the integration guide.

## Checksum
\`\`\`
$(shasum -a 256 "$RELEASE_FILE" | awk '{print $1}')
\`\`\`

## Size
- Compressed: $(du -h "$RELEASE_FILE" | awk '{print $1}')
- Uncompressed: ~416MB

## Changes from stasel/WebRTC
- Built from latest WebRTC main branch
- H.265/HEVC codec enabled
- AV1 codec support added
- macOS 14.0+ minimum (was 10.11)
- Automated build system with configurable options
"

echo "Creating GitHub release: $VERSION"
echo "Release file: $RELEASE_FILE"
echo ""

# Create the release
gh release create "$VERSION" \
    --title "WebRTC $VERSION" \
    --notes "$RELEASE_NOTES" \
    "$RELEASE_FILE" \
    "$PROJECT_ROOT/release/INTEGRATION.md" \
    "$PROJECT_ROOT/xcconfig/WebRTC.xcconfig" \
    "$PROJECT_ROOT/xcconfig/WebRTC-Debug.xcconfig" \
    "$PROJECT_ROOT/xcconfig/WebRTC-Release.xcconfig"

echo ""
echo "Release created successfully!"
echo "View at: https://github.com/steipete/WebRTC/releases/tag/$VERSION"
echo ""
echo "Next steps:"
echo "1. Update Package.swift with the new checksum"
echo "2. Test the Swift Package integration"
echo "3. Update any dependent projects"