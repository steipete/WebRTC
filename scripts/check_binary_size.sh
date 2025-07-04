#!/bin/bash

# Script to check and compare WebRTC binary sizes
# Useful for tracking size optimization progress

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    else
        echo "$(echo "scale=2; $bytes / 1024" | bc) KB"
    fi
}

# Function to calculate percentage
calc_percentage() {
    local old=$1
    local new=$2
    if [ $old -eq 0 ]; then
        echo "N/A"
    else
        local diff=$((new - old))
        local percent=$(echo "scale=2; ($diff * 100) / $old" | bc)
        if (( $(echo "$percent < 0" | bc -l) )); then
            echo "${GREEN}${percent}%${NC}"
        else
            echo "${RED}+${percent}%${NC}"
        fi
    fi
}

echo "=== WebRTC Binary Size Analysis ==="
echo

# Check build output
BUILD_DIR="$PROJECT_ROOT/src/src/out"
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}Error: Build directory not found at $BUILD_DIR${NC}"
    echo "Please run build_webrtc.sh first"
    exit 1
fi

# Find all built configurations
for config_dir in "$BUILD_DIR"/*; do
    if [ -d "$config_dir" ]; then
        config_name=$(basename "$config_dir")
        echo -e "${YELLOW}Configuration: $config_name${NC}"
        
        # Check for main library
        lib_path="$config_dir/obj/libwebrtc.a"
        if [ -f "$lib_path" ]; then
            size=$(stat -f%z "$lib_path" 2>/dev/null || stat -c%s "$lib_path" 2>/dev/null)
            echo "  libwebrtc.a: $(format_bytes $size)"
            
            # Check individual components
            echo "  Components:"
            for component in "$config_dir/obj"/*.a; do
                if [ -f "$component" ] && [ "$component" != "$lib_path" ]; then
                    comp_size=$(stat -f%z "$component" 2>/dev/null || stat -c%s "$component" 2>/dev/null)
                    comp_name=$(basename "$component")
                    if [ $comp_size -gt 10485760 ]; then # Show only >10MB files
                        echo "    $comp_name: $(format_bytes $comp_size)"
                    fi
                fi
            done
        else
            echo -e "  ${RED}libwebrtc.a not found${NC}"
        fi
        echo
    fi
done

# Check final framework
FRAMEWORK_PATH="$PROJECT_ROOT/output/WebRTC.xcframework"
if [ -d "$FRAMEWORK_PATH" ]; then
    echo -e "${YELLOW}Final Framework:${NC}"
    
    # Find the binary
    binary_path="$FRAMEWORK_PATH/macos-arm64/WebRTC.framework/WebRTC"
    if [ -f "$binary_path" ]; then
        size=$(stat -f%z "$binary_path" 2>/dev/null || stat -c%s "$binary_path" 2>/dev/null)
        echo "  WebRTC binary: $(format_bytes $size)"
        
        # Check if we have a previous size recorded
        size_file="$PROJECT_ROOT/.last_binary_size"
        if [ -f "$size_file" ]; then
            last_size=$(cat "$size_file")
            change=$(calc_percentage $last_size $size)
            echo "  Size change: $change"
            
            diff=$((size - last_size))
            if [ $diff -lt 0 ]; then
                echo -e "  ${GREEN}Saved: $(format_bytes ${diff#-})${NC}"
            elif [ $diff -gt 0 ]; then
                echo -e "  ${RED}Increased: $(format_bytes $diff)${NC}"
            fi
        fi
        
        # Save current size
        echo $size > "$size_file"
        
        # Analyze sections
        echo
        echo "  Binary sections:"
        size -m "$binary_path" | grep -E "(__TEXT|__DATA|__LINKEDIT)" | while read line; do
            echo "    $line"
        done
    else
        echo -e "  ${RED}Binary not found${NC}"
    fi
    
    # Check compressed size
    zip_path="$PROJECT_ROOT/output/WebRTC-macOS-arm64-h265.zip"
    if [ -f "$zip_path" ]; then
        zip_size=$(stat -f%z "$zip_path" 2>/dev/null || stat -c%s "$zip_path" 2>/dev/null)
        echo
        echo "  Compressed size: $(format_bytes $zip_size)"
        if [ -f "$binary_path" ]; then
            binary_size=$(stat -f%z "$binary_path" 2>/dev/null || stat -c%s "$binary_path" 2>/dev/null)
            compression_ratio=$(echo "scale=2; (1 - ($zip_size / $binary_size)) * 100" | bc)
            echo "  Compression ratio: ${compression_ratio}%"
        fi
    fi
fi

echo
echo "=== Size Optimization Tips ==="
echo "1. Disable unused codecs in build_config.sh"
echo "2. Set ENABLE_LTO=true for Link-Time Optimization"
echo "3. Set OPTIMIZE_FOR_SIZE=true for size-optimized builds"
echo "4. Disable audio codecs you don't need (G722, iLBC, iSAC)"
echo "5. Consider building without AV1 codec (saves ~80-100MB)"

# Show current configuration
echo
echo "=== Current Configuration ==="
source "$PROJECT_ROOT/build_config.sh" 2>/dev/null || true
echo "LTO: ${ENABLE_LTO:-false}"
echo "Thin LTO: ${ENABLE_THIN_LTO:-false}"
echo "Optimize for size: ${OPTIMIZE_FOR_SIZE:-false}"
echo "Symbol level: ${SYMBOL_LEVEL:-2}"
echo "Audio codecs: Opus=$ENABLE_OPUS, G711=$ENABLE_G711, G722=$ENABLE_G722, iLBC=$ENABLE_ILBC, iSAC=$ENABLE_ISAC"
echo "Video codecs: H265=$ENABLE_H265, VP9=$ENABLE_VP9, AV1=$ENABLE_AV1"