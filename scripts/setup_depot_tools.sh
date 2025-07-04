#!/bin/bash

# Setup depot_tools for WebRTC build
# This script downloads and configures depot_tools required for WebRTC compilation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPOT_TOOLS_DIR="$PROJECT_ROOT/depot_tools"

echo "Setting up depot_tools..."

# Check if depot_tools already exists
if [ -d "$DEPOT_TOOLS_DIR" ]; then
    echo "depot_tools already exists, updating..."
    cd "$DEPOT_TOOLS_DIR"
    git pull
else
    echo "Cloning depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
fi

# Add depot_tools to PATH for this session
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# Update depot_tools
echo "Updating depot_tools..."
cd "$DEPOT_TOOLS_DIR"
./update_depot_tools

echo "depot_tools setup complete!"
echo "To use depot_tools in your current session, run:"
echo "export PATH=\"$DEPOT_TOOLS_DIR:\$PATH\""