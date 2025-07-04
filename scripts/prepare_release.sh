#!/bin/bash

# Prepare WebRTC XCFramework for release as a Swift Package binary target
# This script creates the proper structure and calculates checksums

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/output"
RELEASE_DIR="$PROJECT_ROOT/release"

# Check if XCFramework exists
if [ ! -d "$OUTPUT_DIR/WebRTC.xcframework" ]; then
    echo "Error: WebRTC.xcframework not found. Please run build_all.sh first."
    exit 1
fi

echo "Preparing WebRTC XCFramework for release..."

# Create release directory
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Create XCFramework zip for Swift Package Manager
echo "Creating XCFramework zip..."
cd "$OUTPUT_DIR"
zip -r "$RELEASE_DIR/WebRTC.xcframework.zip" WebRTC.xcframework -x "*.DS_Store"
cd - > /dev/null

# Calculate checksum for Swift Package Manager
echo "Calculating checksum..."
CHECKSUM=$(swift package compute-checksum "$RELEASE_DIR/WebRTC.xcframework.zip")
echo "Checksum: $CHECKSUM"

# Update Package.swift with the correct checksum
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/CHECKSUM_PLACEHOLDER/$CHECKSUM/g" "$PROJECT_ROOT/Package.swift"
else
    sed -i "s/CHECKSUM_PLACEHOLDER/$CHECKSUM/g" "$PROJECT_ROOT/Package.swift"
fi

# Create release info
cat > "$RELEASE_DIR/release_info.json" <<EOF
{
    "version": "$(git describe --tags --always --dirty)",
    "commit": "$(git rev-parse HEAD)",
    "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "checksum": "$CHECKSUM",
    "size": "$(ls -lh "$RELEASE_DIR/WebRTC.xcframework.zip" | awk '{print $5}')",
    "swift_package_url": "https://github.com/steipete/WebRTC.git"
}
EOF

# Create integration instructions
cat > "$RELEASE_DIR/INTEGRATION.md" <<EOF
# WebRTC XCFramework Integration Guide

## Swift Package Manager

Add this to your \`Package.swift\`:

\`\`\`swift
dependencies: [
    .package(url: "https://github.com/steipete/WebRTC.git", from: "1.0.0")
]
\`\`\`

## Xcode Project

1. In Xcode, select File > Add Package Dependencies
2. Enter: \`https://github.com/steipete/WebRTC.git\`
3. Select version rule: "Up to Next Major Version"
4. Click "Add Package"

## XCConfig Integration

1. Copy the \`xcconfig\` folder to your project
2. In your project settings, set the configuration files:
   - Debug: \`WebRTC-Debug.xcconfig\`
   - Release: \`WebRTC-Release.xcconfig\`

## Manual Integration

1. Download \`WebRTC.xcframework.zip\` from releases
2. Unzip and drag \`WebRTC.xcframework\` into your project
3. Ensure "Embed & Sign" is selected

## Framework Info

- **Checksum**: \`$CHECKSUM\`
- **Size**: $(ls -lh "$RELEASE_DIR/WebRTC.xcframework.zip" | awk '{print $5}')
- **Architecture**: arm64 (Apple Silicon)
- **Minimum macOS**: 14.0
- **Codecs**: H.265/HEVC, VP9, Opus
EOF

echo
echo "Release preparation complete!"
echo
echo "Files created:"
echo "  - $RELEASE_DIR/WebRTC.xcframework.zip ($(ls -lh "$RELEASE_DIR/WebRTC.xcframework.zip" | awk '{print $5}')"
echo "  - $RELEASE_DIR/release_info.json"
echo "  - $RELEASE_DIR/INTEGRATION.md"
echo
echo "Package.swift updated with checksum: $CHECKSUM"
echo
echo "To create a GitHub release:"
echo "  1. Tag the commit: git tag v1.0.0"
echo "  2. Push tags: git push --tags"
echo "  3. Create release on GitHub and upload WebRTC.xcframework.zip"