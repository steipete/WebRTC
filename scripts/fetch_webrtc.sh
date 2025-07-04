#!/bin/bash

# Fetch WebRTC source code
# This script downloads the WebRTC source using gclient

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPOT_TOOLS_DIR="$PROJECT_ROOT/depot_tools"
SRC_DIR="$PROJECT_ROOT/src"

# Ensure depot_tools is in PATH
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# Check if depot_tools exists
if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    echo "Error: depot_tools not found. Please run setup_depot_tools.sh first"
    exit 1
fi

# Create source directory
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# Check if .gclient exists
if [ -f ".gclient" ]; then
    echo "WebRTC source already fetched, syncing..."
    gclient sync --with_branch_heads --with_tags
else
    echo "Fetching WebRTC source code..."
    # Configure gclient for WebRTC
    cat > .gclient <<EOF
solutions = [
  {
    "name": "src",
    "url": "https://webrtc.googlesource.com/src.git",
    "deps_file": "DEPS",
    "managed": True,
    "custom_deps": {},
    "custom_vars": {
      "checkout_instrumented_libraries": False,
    },
  },
]
target_os = ["mac", "ios"]
EOF

    # Fetch the source
    gclient sync --with_branch_heads --with_tags
fi

# Get the current WebRTC version
cd "$SRC_DIR/src"
WEBRTC_COMMIT=$(git rev-parse HEAD)
WEBRTC_BRANCH=$(git branch -r --contains HEAD | grep -E 'branch-heads/[0-9]+' | head -1 | sed 's/.*branch-heads\///')

echo "WebRTC source fetched successfully!"
echo "Commit: $WEBRTC_COMMIT"
echo "Branch: $WEBRTC_BRANCH"