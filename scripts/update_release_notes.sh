#!/bin/bash

# Script to update release notes with version clarification

set -euo pipefail

RELEASE_TAG="M139"

echo "Updating release notes for $RELEASE_TAG..."

# Update the release description
gh release edit "$RELEASE_TAG" --notes "# WebRTC Framework $RELEASE_TAG

**⚠️ Version Note**: Built from WebRTC main branch (latest development), not from the M139 stable branch. This provides the newest features but may include experimental changes.

Built from WebRTC commit: \`6154b71a15\`
Build date: 2025-07-04

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
    .package(url: \"https://github.com/steipete/WebRTC.git\", from: \"M139\")
]
\`\`\`

### Manual Integration
Download \`WebRTC.xcframework.zip\` from the assets below and follow the integration guide.

## Build Information
- Branch: main (development)
- Provides latest WebRTC features
- Approximately 6-12 weeks ahead of stable
- For production, consider building from a stable milestone branch

## Checksum
\`\`\`
4feb66305109584230e99d4bf2f8c91401001fc34872695e2c7a70dcf5b63c40
\`\`\`

## Size
- Compressed: 115MB
- Uncompressed: ~416MB

## Changes from stasel/WebRTC
- Built from latest WebRTC main branch
- H.265/HEVC codec enabled
- AV1 codec support added
- macOS 14.0+ minimum (was 10.11)
- Automated build system with configurable options
"

echo "Release notes updated!"