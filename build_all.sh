#!/bin/bash

# Master build script for WebRTC with H265 support on macOS ARM64
# This script runs all steps needed to build WebRTC from scratch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check macOS version
    os_version=$(sw_vers -productVersion)
    print_status "macOS version: $os_version"
    
    # Check architecture
    arch=$(uname -m)
    if [ "$arch" != "arm64" ]; then
        print_error "This script requires Apple Silicon (ARM64). Current architecture: $arch"
        exit 1
    fi
    print_status "Architecture: $arch ✓"
    
    # Check Xcode
    if ! xcode-select -p &> /dev/null; then
        print_error "Xcode command line tools not installed. Please run: xcode-select --install"
        exit 1
    fi
    print_status "Xcode: $(xcodebuild -version | head -1) ✓"
    
    # Check disk space
    available_space=$(df -H / | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( $(echo "$available_space < 60" | bc -l) )); then
        print_warning "Low disk space: ${available_space}GB available. Recommended: 60GB+"
    else
        print_status "Disk space: ${available_space}GB available ✓"
    fi
    
    # Check for required tools
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required. Please install it via Homebrew: brew install python3"
        exit 1
    fi
    print_status "Python 3: $(python3 --version) ✓"
}

# Main build process
main() {
    print_status "Starting WebRTC build process..."
    print_status "This will take 1-3 hours depending on your internet speed and Mac performance."
    echo
    
    # Check requirements first
    check_requirements
    echo
    
    # Load build configuration
    if [ -f "$PROJECT_ROOT/build_config.sh" ]; then
        source "$PROJECT_ROOT/build_config.sh"
        print_status "Build configuration loaded"
        if [ "$VERBOSE_BUILD" = "true" ]; then
            print_config
        fi
    fi
    echo
    
    # Step 1: Setup depot_tools
    print_status "Step 1/4: Setting up depot_tools..."
    if [ ! -d "$PROJECT_ROOT/depot_tools" ]; then
        "$PROJECT_ROOT/scripts/setup_depot_tools.sh"
    else
        print_status "depot_tools already exists, skipping setup"
    fi
    
    # Add depot_tools to PATH
    export PATH="$PROJECT_ROOT/depot_tools:$PATH"
    echo
    
    # Step 2: Fetch WebRTC source
    print_status "Step 2/4: Fetching WebRTC source code..."
    print_warning "This will download ~20GB of data"
    "$PROJECT_ROOT/scripts/fetch_webrtc.sh"
    echo
    
    # Step 3: Build WebRTC
    print_status "Step 3/4: Building WebRTC..."
    print_warning "This will take 30-60 minutes"
    "$PROJECT_ROOT/scripts/build_webrtc.sh"
    echo
    
    # Step 4: Package framework
    print_status "Step 4/4: Packaging framework..."
    "$PROJECT_ROOT/scripts/package_framework.sh"
    echo
    
    # Final summary
    print_status "Build completed successfully! 🎉"
    echo
    print_status "Output files:"
    echo "  - XCFramework: $PROJECT_ROOT/output/WebRTC.xcframework"
    echo "  - Compressed: $PROJECT_ROOT/output/WebRTC-macOS-arm64-h265.zip"
    echo
    print_status "Framework details:"
    echo "  - Size: $(ls -lh "$PROJECT_ROOT/output/WebRTC-macOS-arm64-h265.zip" | awk '{print $5}')"
    echo "  - Architecture: arm64"
    echo "  - H265 Support: Enabled"
    echo "  - Minimum macOS: 14.0"
    echo
    print_status "To use in your project:"
    echo "  1. Unzip WebRTC-macOS-arm64-h265.zip"
    echo "  2. Drag WebRTC.xcframework into your Xcode project"
    echo "  3. Ensure 'Embed & Sign' is selected"
}

# Run main function
main "$@"