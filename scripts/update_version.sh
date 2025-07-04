#!/bin/bash

# Script to update version references across the project
# Usage: ./scripts/update_version.sh M139

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 M139"
    exit 1
fi

NEW_VERSION="$1"
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Updating version to: $NEW_VERSION"

# Update Package.swift
if [ -f "$PROJECT_ROOT/Package.swift" ]; then
    echo "Updating Package.swift..."
    sed -i '' "s|download/v[0-9.]*|download/$NEW_VERSION|g" "$PROJECT_ROOT/Package.swift"
fi

# Update release_info.json if it exists
if [ -f "$PROJECT_ROOT/release/release_info.json" ]; then
    echo "Updating release_info.json..."
    # Use jq if available, otherwise use sed
    if command -v jq &> /dev/null; then
        jq --arg version "$NEW_VERSION" '.version = $version' "$PROJECT_ROOT/release/release_info.json" > "$PROJECT_ROOT/release/release_info.json.tmp"
        mv "$PROJECT_ROOT/release/release_info.json.tmp" "$PROJECT_ROOT/release/release_info.json"
    else
        sed -i '' "s|\"version\": \"[^\"]*\"|\"version\": \"$NEW_VERSION\"|g" "$PROJECT_ROOT/release/release_info.json"
    fi
fi

# Update INTEGRATION.md
if [ -f "$PROJECT_ROOT/release/INTEGRATION.md" ]; then
    echo "Updating INTEGRATION.md..."
    sed -i '' "s|from: \"[0-9.]*\"|from: \"$NEW_VERSION\"|g" "$PROJECT_ROOT/release/INTEGRATION.md"
fi

# Update README.md version references
if [ -f "$PROJECT_ROOT/README.md" ]; then
    echo "Updating README.md..."
    sed -i '' "s|download/v[0-9.]*|download/$NEW_VERSION|g" "$PROJECT_ROOT/README.md"
    sed -i '' "s|from: \"[0-9.]*\"|from: \"$NEW_VERSION\"|g" "$PROJECT_ROOT/README.md"
fi

echo "Version updated to $NEW_VERSION"
echo ""
echo "Don't forget to:"
echo "1. Update the checksum in Package.swift after building and releasing"
echo "2. Create a GitHub release with tag: $NEW_VERSION"
echo "3. Upload the WebRTC.xcframework.zip to the release"